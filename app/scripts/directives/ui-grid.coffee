# The grid component is responsible for laying out items in a grid/matrix style, with headers above each
# group of items.
#
# This component operates by manipulating the visibility and position of its child elements to reflect the
# state of a queryResult scope variable (defined in nr-card-service.coffee). All DOM elements must be
# present in the document when the directive initializes.
#
# This directive is intended to be loosely bound to Ono-Sendai, and can possibly be released independently
# at some point.
#
# LIMITATIONS
#   * Grid items must all be the same size
#
angular.module('onoSendai')
  .directive('grid', ($window, $q, $log, $animate, $timeout, cssUtils) ->
    restrict: 'E'
    transclude: true
    template: '<div class="content-container" ng-transclude></div>'
    scope: {
      queryResult: '='
      zoom: '='
      selection: '='
    }
    link: (scope, element, attrs) ->
      container = element.find('.content-container')
      containerWidth = null
      inContinuousZoom = false
      needsLayout = false        # true if a layout is attempted while the grid is hidden
      pendingLayout = null       # Promise

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

      # This is multiplied by scope.zoom to produce the transform:scale value. It is necessary because we swap
      # in lower resolution images before doing most transformations.
      inverseDownscaleFactor = 1

      scrollParent = element.parents('.scrollable').first()
      scrollTop = scrollParent.scrollTop()


      # Returns true if the container has changed width since last invocation
      hasContainerChangedWidth = ->
        if containerWidth != (newContainerWidth = container.width())
          containerWidth = newContainerWidth
          $log.debug 'Container width changed', containerWidth
          true
        else
          false
      hasContainerChangedWidth()

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

      performGridLayout = ->
        items = gridItemsAndHeaders
        if !items? or !items.length
          return

        firstHeader = $(_.find(items, (item) -> item.classList.contains('grid-header')))

        # NOTE: We get the second item, and not the first, because we need an item to attach a transition
        #       event listener to *an* item, and the first item doesn't necessarily move. :)
        # SECOND NOTE:
        #       Transitions are currently not supported, but I'm leaving this around in case I change my mind.
        notFirst = true
        secondItem = $(_.find(items, (item) -> item.classList.contains('grid-item') and (notFirst = !notFirst)))

        itemSize = getItemSize('item', secondItem)
        headerSize = getItemSize('header', firstHeader, true)

        availableWidth = containerWidth - hMargin * 2
        numColumns = Math.floor((availableWidth + minimumGutterWidth) / (itemSize.width + minimumGutterWidth))
        numGutters = numColumns - 1 or 1
        numRows = Math.ceil(items.length / numColumns)
        gutterWidth = (availableWidth - (numColumns * itemSize.width)) / numGutters
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

        # Resizes the grid
        lastRow = rowInfos[lastVisibleRow]
        newContainerHeight = lastRow.position + lastRow.height
        container.height(newContainerHeight)

        # Scroll baby!
        scrollToFocusedElement()


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
            else
              item.classList.add('hidden')

        if !_.isEmpty(headerLayouts)
          items = gridHeaders
          len = items.length
          for layout, i in headerLayouts
            if i == gridHeaders.length
              break

            item = gridHeaders[i]
            item.classList.remove('invisible')
            item.style[transformProperty] =
              "translate3d(#{layout.x}px, #{layout.y}px, 0)"

        return

      # Downscales the images if required, runs the current layout algorithm, then upscales the
      # images back to their original sizing.
      layoutNow = (scaleImages = false) ->
        # No point in doing any work if nobody sees it
        if element.is(':hidden')
          needsLayout = true
          return

        # First, we *might* downscale the images. It may be done earlier in the process (for example, in
        # zoom start/end)
        if scaleImages
          downscaleItems().then(performGridLayout).then(upscaleItems)
        else
          performGridLayout()

        needsLayout = false
        pendingLayout = null

      # We provide a debounced version, so we don't layout too much during user input
      layout = _.debounce(layoutNow, 300)

      # Reacts to messages sent from above triggering layouts
      scope.$on 'layout', layoutForced = (e, mode) ->
        if mode != 'grid'
          return

        $log.debug 'Received layout event. Queuing layout'

        pendingLayout = $timeout ->
          if hasContainerChangedWidth() or needsLayout
            $log.debug 'Laying out (layout event)'
            layoutNow(false)
          scrollToFocusedElement()


      # *~*~*~*~ SCROLLING

      scrollToFocusedElement = ->
        if !focusedElement? or rowInfos.length <= focusedElement.row
          scrollParent.scrollTop(0)
        else
          rowInfo = rowInfos[focusedElement.row]
          scrollTop = rowInfo.position + rowInfo.height * focusedElementChop
          scrollParent.scrollTop(scrollTop)

      scrollToTop = ->
        scrollParent.scrollTop(0)

      # Determine which grid item or header is in the top left, so that we can keep it focused through zooming
      scrollChanged = ->
        if inContinuousZoom or !container.is(':visible')
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
        if scope.zoom > 0.6
          1
        else if scope.zoom > 0.35
          2

      # Change the resolution of grid items so the GPU uses less texture memory during transforms. We
      # will record the scale factor so that we can use transform: scale CSS to have them appear at the same
      # correct size.
      #
      # [fix] This doesn't appear to do anything in Firefox
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


      # *~*~*~*~ SELECTION CHANGES

      # When the selection changes, change the focused element
      scope.$watch 'selection', (newSelection) ->
        if !newSelection?
          return

        changeFocusToSelection = ->
          selectionElement = element.find("[grid-id='#{ newSelection.id }']")
          if !selectionElement.length
            $log.warn "No element found with grid-id #{ newSelection.id }"
            return

          $log.debug 'New focus element determined "%s"', selectionElement.attr('title')

          focusedElement = selectionElement.get(0)
          focusedElementChop = -0.02 # Negative chop to make the scroll position feel a bit more natural

        if firstLayout
          # We timeout here for the case where the user lands on the card page, and we have to wait for the
          # DOM to contain all the cards
          $timeout changeFocusToSelection
        else
          changeFocusToSelection()


      # *~*~*~*~ QUERY CHANGES

      firstLayout = true
      scope.$watch('queryResult', queryResultChanged = (newVal) ->
        $log.debug 'Laying out (query result changed)'
        queryResult = newVal

        # If we have a pending layout (maybe due to a layout event in the same frame of the event loop),
        # the new query result takes precedence.
        if pendingLayout?
          $log.debug 'Preempting queued layout'
          $timeout.cancel pendingLayout

        pendingLayout = $timeout ->
          if !queryResult?
            return

          invalidateGridContents(queryResult)
          layoutPromise = layoutNow(firstLayout)
          scrollToTop()
          firstLayout = false
        return)


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

      scope.$watch('zoom', zoomChanged = (newVal) ->
        layoutNow())


      # *~*~*~*~ WINDOW RESIZING

      # Watch for resizes that may affect grid size, requiring a re-layout
      $($window).resize windowResized = ->
        if hasContainerChangedWidth()
          $log.debug 'Laying out grid (grid width change)'
          layoutNow(false)
  )
