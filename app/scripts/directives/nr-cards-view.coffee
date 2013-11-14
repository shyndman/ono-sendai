# This component is responsible for dealing with cards, including user input and layout.
angular.module('deckBuilder')
  .directive('nrCardsView', ($window, $q, $log, $animate, $timeout, cssUtils) ->
    restrict: 'E'
    transclude: true
    templateUrl: '/views/directives/nr-cards-view.html'
    scope: {
      queryResult: '='
      zoom: '='
      selection: '='
    }
    link: (scope, element, attrs) ->
      layoutMode = 'grid'
      container = element.find('.content-container')
      containerWidth = container.width()
      inContinuousZoom = false

      minimumGutterWidth = 20
      vMargin = 10
      hMargin = 6                # Margin at the edges

      gridItemsById = null       # Map from grid identifiers to their associated DOM elements
      gridItems = $([])          # Query result ordered items
      gridHeaders = $([])        # Query result ordered headers
      gridItemsAndHeaders = null # Query result ordered grid items and headers
      focusedElement = null      # Element visible in the top left of the grid
      focusedElementChop = null  # Percentage of the focused element chopped off above
      rowInfos = []              # Contains row heights, y positions and the first DOM element in each
      itemLayouts = []           # Contains the positioning, scale and opacity information for each item
      headerLayouts = []         # Ditto, for headers
      sizeCache = {}             # Caches (expensive to calculate) element sizes at various scales
      queryResult = null         # The most recent query result

      transformProperty = cssUtils.getVendorPropertyName('transform')

      # Names of CSS classes mapped to whether or not they should be applied to a grid item. Individual
      # item layouts can override any of these values.
      defaultItemClasses =
        'prev': false
        'prev-2': false
        'prev-1': false
        'next': false
        'next-2': false
        'next-1': false
        'current': false

      # This is multiplied by scope.zoom to produce the transform:scale value. It is necessary because we swap
      # in lower resolution images before doing most transformations.
      inverseDownscaleFactor = 1

      # First scrollable element containing this one. We toggle its overflow state depending on whether
      # we're in detail mode or grid mode.
      scrollParent = element.parents('.scrollable').first()
      scrollParentOverflow = scrollParent.css('overflow')
      scrollParentH = scrollParent.height()
      scrollTop = scrollParent.scrollTop()


      # Returns true if the container has changed width since last invocation
      hasContainerChangedWidth = ->
        if containerWidth != (newContainerWidth = container.width())
          containerWidth = newContainerWidth
          scrollParentH = scrollParent.height()
          true
        else
          false

      # Returns the item identifier for the provided element.
      getItemId = (ele) ->
        ele.attributes['grid-id'].value

      # Recalculates the lists of DOM elements participating in the grid, ordered by the provided query result.
      invalidateGridContents = (queryResult) ->
        gridItems = container.find('.grid-item')
        gridHeaders = container.find('.grid-header')

        if !gridItemsById?
          gridItemsById =
            _.object(_.map(gridItems, (ele) -> [ getItemId(ele), ele ]))

        # Sort the grid items and headers. Push filtered items to the back of the list.
        gridItemsAndHeaders = $(queryResult.applyOrdering(gridItems.add(gridHeaders), getItemId))
        gridItems = $(queryResult.applyOrdering(gridItems, getItemId))
        gridHeaders = $(queryResult.applyOrdering(gridHeaders, getItemId))

      # NOTE Assumes uniform sizing for all grid items of a given type (which in our case is not a problem,
      # but we end up re-using this, consider it)
      getItemSize = (type, item, noScale = false) ->
        scaleFactor =
          if noScale
            1
          else
            scope.zoom * inverseDownscaleFactor

        # NOTE: These are extremely expensive calculations. Do them once, only.
        cacheKey = "#{type}:#{inverseDownscaleFactor}"
        sizeCache[cacheKey] ?=
          width:  parseFloat(item.css('width'))
          height: parseFloat(item.css('height'))

        baseSize = sizeCache[cacheKey]

        {
          width: baseSize.width * scaleFactor
          height: baseSize.height * scaleFactor
        }

      isGridItem = (item) ->
        item.classList.contains('grid-item')

      isGridHeader = (item) ->
        item.classList.contains('grid-header')

      # Returns a promise that is resolved when any transitions complete, or undefined if there
      # is no transition.
      performGridLayout = ->
        items = gridItemsAndHeaders
        if !items? or !items.length
          return

        # Remove the scroll lock-down, if we've been in detail mode previously
        setScrollerOverflow('')

        firstHeader = $(_.find(items, (item) -> item.classList.contains('grid-header')))
        # NOTE: We get the second item, and not the first, because we need an item to attach a transition
        #       event listener to *an* item, and the first item doesn't necessarily move. :)
        notFirst = true
        secondItem = $(_.find(items, (item) -> item.classList.contains('grid-item') and (notFirst = !notFirst)))

        itemSize = getItemSize('item', secondItem)
        headerSize = getItemSize('header', firstHeader, true)

        availableWidth = containerWidth - hMargin * 2
        numColumns = Math.floor((availableWidth + minimumGutterWidth) / (itemSize.width + minimumGutterWidth))
        numGutters = numColumns - 1
        numRows = Math.ceil(items.length / numColumns)

        gutterWidth  = (availableWidth - (numColumns * itemSize.width)) / numGutters
        colPositions = (i * (itemSize.width + gutterWidth) + hMargin for i in [0...numColumns])
        rowInfos = []
        itemLayouts = []
        headerLayouts = []

        groupItemIdx = 0
        baseRow = 0

        # Helper function for calculating row information, such as sizing (modifies rowInfos in enclosing scope)
        calculateNextRow = (firstElement, headerRow = false) ->
          lastRow = _.last(rowInfos)
          rowHeight = if headerRow then headerSize.height else itemSize.height
          rowHeight += 2 * vMargin
          rowPosition = if lastRow then lastRow.position + lastRow.height else 0

          rowInfo = firstElement: firstElement, height: rowHeight, position: rowPosition
          rowInfos.push rowInfo
          rowInfo

        # Loop over items, calculating their coordinates
        lastVisibleRow = 0
        for item, i in items
          if isGridItem(item)
            row = Math.floor(groupItemIdx / numColumns) + baseRow
            if row == rowInfos.length
              lastVisibleRow = row if queryResult.isShown(getItemId(item))
              calculateNextRow(item)

            itemLayouts.push(
              x: colPositions[groupItemIdx % numColumns]
              y: rowInfos[row].position + vMargin
            ) - 1
            item.row = row
            groupItemIdx++

          else # if isGridHeader(item)
            rowInfo = calculateNextRow(item, true)
            headerLayouts.push(
              x: 0
              y: rowInfo.position + vMargin
            )
            item.row = rowInfos.length - 1

            # Update bookkeeping for row positioning
            baseRow = rowInfos.length
            groupItemIdx = 0

        applyItemStyles()
        scrollToFocusedElement()

        # Resizes the grid, possibly after transition completion
        lastRow = rowInfos[lastVisibleRow]
        newContainerHeight = lastRow.position + lastRow.height
        resizeGrid = -> container.height(newContainerHeight)

        # If we're in transition mode, return a promise that will resolve after
        # the transition has completed.
        if element.hasClass('transitioned')
          transitionPromise = cssUtils.getTransitionEndPromise(secondItem)

          # Resize the grid immediately if its going to be growing
          if newContainerHeight > container.height()
            resizeGrid()
            transitionPromise
          else
            transitionPromise.then(resizeGrid)
        else
          resizeGrid()

      performDetailLayout = ->
        items = gridItems
        if !items.length
          return

        # Ensure that we aren't scrolling.
        setScrollerOverflow('hidden')

        # Work out base Y coordinate
        baseY = scrollTop
        baseY += 60
        nextPrevY = baseY + 26

        selEle = gridItemsById[scope.selection.id]

        for item, i in gridHeaders
          layout = headerLayouts[i] ?= {}
          layout.opacity = 0

        skipCount = 0
        for item, i in gridItems
          if skipCount > 0
            skipCount--
            continue

          layout = itemLayouts[i] ?= {}
          layout.opacity = 0
          layout.classes = hidden: true

          if item == selEle
            if i - 2 >= 0 # current - 2
              _.extend itemLayouts[i - 2],
                zoom: 0.7
                classes:
                  'prev': true
                  'prev-2': true
                x: 0
                y: nextPrevY

            if i - 1 >= 0 # current - 1 (previous)
              _.extend itemLayouts[i - 1],
                zoom: 0.7
                classes:
                  'prev': true
                  'prev-1': true
                x: 30
                y: nextPrevY

            _.extend layout,
              zoom: 0.9
              classes:
                'current': true
              x: (containerWidth - 680) / 2 + 26 # TODO Pull the literal from CSS
              y: baseY
              rotationY: 0

            if i + 1 < gridItems.length # current + 1 (next)
              itemLayouts[i + 1] ?= {} # XXX Barf. Sloppy.
              _.extend itemLayouts[i + 1],
                zoom: 0.7
                classes:
                  'next': true
                  'next-1': true
                x: containerWidth - 295 - 30
                y: nextPrevY

            if i + 2 < gridItems.length # current + 2
              itemLayouts[i + 2] ?= {} # XXX Barf. Sloppy.
              _.extend itemLayouts[i + 2],
                classes:
                  'next': true
                  'next-2': true
                zoom: 0.7
                x: containerWidth - 295
                y: nextPrevY

            skipCount = 2

        applyItemStyles()
        return

      applyItemStyles = ->
        if !_.isEmpty(itemLayouts)
          items = gridItems
          len = items.length
          defaultZoom = Number(scope.zoom)

          for layout, i in itemLayouts
            if i == gridItems.length
              break

            item = gridItems[i]

            if queryResult.isShown(getItemId(item))
              $(item).removeClass('hidden')
              newStyle = "translate3d(#{ layout.x }px, #{ layout.y }px, 0)
                          scale(#{ (layout.zoom ? defaultZoom) * inverseDownscaleFactor })"
              new_zIndex = layout.zIndex ? len - 1

              # Don't set style properties if we don't have to. Their invalidation is a performance killer.
              if item.style[transformProperty] isnt newStyle
                item.style[transformProperty] = newStyle

              # Apply CSS classes
              cssClasses = _.defaults(layout.classes ? {}, defaultItemClasses)
              for cls, apply of cssClasses
                # NOTE We don't use classList.toggle(cls, force) here, because IE11 doesn't
                #      implement it properly.
                if apply
                  item.classList.add(cls)
                else
                  item.classList.remove(cls)
            else
              item.classList.add('hidden')

        if !_.isEmpty(headerLayouts)
          items = gridHeaders
          len = items.length
          for layout, i in headerLayouts
            if i == gridHeaders.length
              break

            item = gridHeaders[i]

            if layoutMode == 'grid'
              item.classList.remove('hidden')
              item.style[transformProperty] =
                "translate3d(#{layout.x}px, #{layout.y}px, 0)"
            else
              item.classList.add('hidden')

        return


      # Downscales the images if required, runs the current layout algorithm, then upscales the
      # images back to their original sizing.
      layoutNow = (scaleImages = false) ->
        # First, we *might* downscale the images. It may be done earlier in the process (for example, in
        # zoom start/end)
        scalePromise =
          if scaleImages
            downscaleItems()
          else
            $q.when()

        # Determines the layout function based on the mode we're in
        layoutFn =
          if layoutMode is 'grid'
            performGridLayout
          else
            performDetailLayout

        # Chain it all together
        scalePromise
          .then(layoutFn)
          .then(->
            if scaleImages
              upscaleItems())

      # We provide a debounced version, so we don't layout too much during user input
      layout = _.debounce(layoutNow, 300)


      # *~*~*~*~ SCROLLING

      # Optimization to prevent unnecessary reflows by invoking jQuery.css. We store the scroll parent's overflow
      # value around, and only set it if required. This assumes no one else is tinkering with the value.
      setScrollerOverflow = (val) ->
        if scrollParentOverflow != val
          scrollParent.css('overflow', val)
          scrollParentOverflow = val


      # NOTE Currently does not animate, unless I figure out a better way to do it. Naive approach
      #      is too jumpy.
      scrollToFocusedElement = ->
        if !focusedElement? or rowInfos.length <= focusedElement.row
          scrollParent.scrollTop(0)
        else
          rowInfo = rowInfos[focusedElement.row]
          scrollTop = rowInfo.position + rowInfo.height * focusedElementChop
          scrollParent.scrollTop(scrollTop)

      # Determine which grid item or header is in the top left, so that we can keep it focused through zooming
      scrollChanged = ->
        if inContinuousZoom
          return

        scrollTop = scrollParent.scrollTop()

        # Find the focused row
        i = _.sortedIndex(rowInfos, position: scrollTop, (info) -> info.position) - 1
        i = 0 if i < 0
        rowInfo = rowInfos[i]

        if focusedElement isnt rowInfo.firstElement
          $log.debug 'New focus element determined "%s"', $(rowInfo.firstElement).attr('title')

        # Grab the element
        focusedElement = rowInfo.firstElement
        focusedElementChop = (scrollTop - rowInfo.position) / rowInfo.height

      scrollParent.scroll(_.debounce(scrollChanged, 100))


      # *~*~*~*~ SCALING

      isUpscaleRequired = ->
        scope.zoom > 0.35

      upscaleTo = ->
        if scope.zoom > 0.5
          1
        else if scope.zoom > 0.35
          2

      # Change the resolution of grid items so the GPU uses less texture memory during transforms. We
      # will record the scale factor so that we can use transform: scale CSS to have them appear at the same
      # correct size.
      #
      # TODO This doesn't appear to do anything in Firefox
      downscaleItems = ->
        scale = 3
        $log.debug "Downscaling grid items to 1/#{ scale }"
        scaleItems(scale)

      upscaleItems = ->
        if isUpscaleRequired()
          scale = upscaleTo()
          $log.debug "Upscaling grid items to 1/#{ scale }"
          scaleItems(scale)
        else
          $log.debug 'Upscaling not performed (zoom level too low)'
          $q.when()

      scaleItems = (scaleFactor) ->
        if inverseDownscaleFactor is scaleFactor
          $q.when() # Return a resolved promise if we have nothing to do
        else
          # Record whether we're marked as transitioned, which we will restore after
          # a defer.
          hasTransitioned = element.hasClass('transitioned')
          element.removeClass('transitioned')

          # Remove the old scale, and add the new one if necessary
          element.removeClass("downscaled-1-#{ inverseDownscaleFactor }")
          inverseDownscaleFactor = scaleFactor
          element.toggleClass("downscaled-1-#{ scaleFactor }", scaleFactor isnt 1)
          applyItemStyles()

          # Give the browser an opportunity to update the visuals, before restoring
          # the transitioned class.
          if hasTransitioned
            $timeout -> element.toggleClass('transitioned', hasTransitioned)
          else
            $q.when() # Empty promise :)


      # *~*~*~*~ CARDS

      selectionChanged = (newVal, oldVal) ->
        layoutMode =
          if newVal
            $log.debug 'Item selected. Displaying in detail mode'
            'detail'
          else
            $log.debug 'No selection. Displaying items in grid mode'
            'grid'
        layoutNow()
      scope.$watch('selection', selectionChanged)

      queryResultChanged = (newVal) ->
        $log.debug 'Laying out grid (query)'
        queryResult = newVal
        $timeout ->
          invalidateGridContents(queryResult)
          layoutNow(element.hasClass('transitioned'))
        return
      scope.$watch('queryResult', queryResultChanged)


      # *~*~*~*~ ZOOMING

      scope.$on 'zoomStart', ->
        console.groupCollapsed?('Zoom')
        $timeout -> downscaleItems()
        inContinuousZoom = true

      scope.$on 'zoomEnd', ->
        $log.debug "New zoom level: #{ scope.zoom }"
        upscaleItems()
        inContinuousZoom = false
        console.groupEnd?('Zoom')

      zoomChanged = (newVal) ->
        layoutNow()

      scope.$watch('zoom', zoomChanged)


      # *~*~*~*~ WINDOW RESIZING

      # Watch for resizes that may affect grid size, requiring a re-layout
      windowResized = ->
        if hasContainerChangedWidth()
          $log.debug 'Laying out grid (grid width change)'
          layoutNow(false)

      $($window).resize(windowResized)
  )
