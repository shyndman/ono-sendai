# This component is responsible for dealing with cards, including user input and layout.

angular.module('deckBuilder')
  .directive('nrCardsView', ($window, $q, $log, $timeout, cssUtils) ->
    restrict: 'E'
    transclude: true
    templateUrl: 'views/directives/nr-cards-view.html'
    scope: {
      cardFilter: '='
      zoom: '='
      selectedCard: '='
    }
    link: (scope, element, attrs) ->
      layoutMode = 'grid'
      grid = element.find('.grid')
      gridWidth = grid.width()
      minimumGutterWidth = 20
      vMargin = 10
      hMargin = 6
      inContinuousZoom = false
      gridItems = null
      gridHeaders = null
      gridItemsAndHeaders = null
      focusedElement = null # Element visible in the top left of the grid
      focusedElementChop = null # Percentage of the focused element chopped off above
      rowInfos = []
      itemPositions = []
      headerPositions = []
      sizeCache = {}
      transformProperty = cssUtils.getVendorPropertyName('transform')

      # This is multiplied by scope.zoom to produce the transform:scale value. It is necessary
      # because we swap in lower resolution images before doing most transformations.
      inverseDownscaleFactor = 1

      # Returns true if the grid has changed width
      hasGridChangedWidth = ->
        if gridWidth != (newGridWidth = grid.width())
          gridWidth = newGridWidth
          true
        else
          false

      invalidateGridContents = ->
        itemSel = '.grid-item:not(.ng-hide)'
        headerSel = '.grid-header:not(.ng-hide)'

        gridItems = element.find(itemSel)
        gridHeaders = element.find(headerSel)
        gridItemsAndHeaders = element.find("#{ itemSel }, #{ headerSel }")

      # NOTE Assumes uniform sizing for all grid items (which in our case is not a problem)
      getItemSize = (type, item, noScale = false) ->
        scaleFactor =
          if noScale
            1
          else
            scope.zoom * inverseDownscaleFactor

        # NOTE: These are extremely expensive calculations. Do them once, only.
        sizeCache[type] ?= {}
        sizeCache[type][inverseDownscaleFactor] ?=
          width: parseFloat(item.css('width'))
          height: parseFloat(item.css('height'))
        baseSize = sizeCache[type][inverseDownscaleFactor]

        {
          width: baseSize.width * scaleFactor
          height: baseSize.height * scaleFactor
        }

      isGridItem = (item) ->
        item.classList.contains('grid-item')

      isGridHeader = (item) ->
        item.classList.contains('grid-header')

      # Returns a promise that is resolved when any transitions complete, or undefined if there is no
      # transition.
      performGridLayout = ->
        items = gridItemsAndHeaders
        if !items.length
          return

        firstHeader = $(_.find(items, (item) -> item.classList.contains('grid-header')))
        # NOTE: We get the second item, and not the first, because we need an item to attach a transition
        #       event listener to *an* item, and the first item doesn't necessarily move. :)
        notFirst = true
        secondItem = $(_.find(items, (item) -> item.classList.contains('grid-item') and (notFirst = !notFirst)))

        itemSize = getItemSize('item', secondItem)
        headerSize = getItemSize('header', firstHeader, true)

        availableGridWidth = gridWidth - hMargin * 2
        numColumns = Math.floor((availableGridWidth + minimumGutterWidth) / (itemSize.width + minimumGutterWidth))
        numGutters = numColumns - 1
        numRows = Math.ceil(items.length / numColumns)

        gutterWidth  = (availableGridWidth - (numColumns * itemSize.width)) / numGutters
        colPositions = (i * (itemSize.width + gutterWidth) + hMargin for i in [0...numColumns])
        rowInfos = []
        itemPositions = []
        headerPositions = []

        groupItemIdx = 0
        baseRow = 0

        # Helper function for calculating row information, such as sizing (modifies variables in enclosing scope)
        calculateNextRow = (firstElement, headerRow = false) ->
          lastRow = _.last(rowInfos)
          rowHeight = if headerRow then headerSize.height else itemSize.height
          rowHeight += 2 * vMargin
          rowPosition = if lastRow then lastRow.position + lastRow.height else 0

          rowInfo = firstElement: firstElement, height: rowHeight, position: rowPosition
          rowInfos.push rowInfo
          rowInfo

        # Loop over items, calculating their coordinates
        for item, i in items
          if isGridItem(item)
            row = Math.floor(groupItemIdx / numColumns) + baseRow
            if row == rowInfos.length
              calculateNextRow(item)

            item.idx = itemPositions.push(
              x: colPositions[groupItemIdx % numColumns],
              y: rowInfos[row].position + vMargin
            ) - 1
            item.row = row
            groupItemIdx++

          else # if isGridHeader(item)
            rowInfo = calculateNextRow(item, true)
            item.idx = headerPositions.push(
              x: 0
              y: rowInfo.position + vMargin
            ) - 1
            item.row = rowInfos.length - 1

            # Update bookkeeping for row positioning
            baseRow = rowInfos.length
            groupItemIdx = 0

        applyItemStyles()
        lastRow = _.last(rowInfos)

        transitionDuration =
          if element.hasClass('transitioned')
            cssUtils.getTransitionDuration(items.first())
          else
            0
        scrollToFocusedCard(transitionDuration)

        # Resizes the grid, possibly after transition completion
        newGridHeight = lastRow.position + lastRow.height
        resizeGrid = -> grid.height(newGridHeight)

        # If we're in transition mode, return a promise that will resolve after
        # the transition has completed.
        if element.hasClass('transitioned')
          transitionPromise = cssUtils.getTransitionEndPromise(secondItem)

          # Resize the grid immediately if its going to be growing
          if newGridHeight > grid.height()
            resizeGrid()
            transitionPromise
          else
            transitionPromise.then(resizeGrid)
        else
          resizeGrid()

      #
      performDetailLayout = ->
        items = gridItems
        if !items.length
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

        scalePromise
          .then(layoutFn)
          .then(->
            if scaleImages
              upscaleItems())

      # We provide a debounced version, so we don't layout too much during user input
      layout = _.debounce(layoutNow, 300)

      applyItemStyles = ->
        if !_.isEmpty(itemPositions)
          items = gridItems
          len = items.length
          for pos, i in itemPositions
            break if i == gridItems.length
            item = gridItems[i]

            item.style.zIndex = len - i
            item.style[transformProperty] =
              "translate3d(#{ pos.x }px, #{ pos.y }px, 0)
                     scale(#{ Number(scope.zoom) * inverseDownscaleFactor })"

        if !_.isEmpty(headerPositions)
          len = items.length
          for pos, i in headerPositions
            break if i == gridHeaders.length
            item = gridHeaders[i]

            item.style.zIndex = len - i
            item.style[transformProperty] =
              "translate3d(#{headerPositions[i].x}px, #{headerPositions[i].y}px, 0)"

        return

      # Watch for resizes that may affect grid size, requiring a re-layout
      windowResized = ->
        if hasGridChangedWidth()
          $log.debug 'Laying out grid (grid width change)'
          layoutNow(false)

      $($window).resize(windowResized)

      # *~*~*~*~ SCROLLING

      scrollParent = element.parents('.scrollable').first()

      # NOTE Currently does not animate, unless I figure out a better way to do it. Naive approach
      #      is too jumpy.
      scrollToFocusedCard = ->
        if !focusedElement? or rowInfos.length <= focusedElement.row
          scrollParent.scrollTop(0)
        else
          rowInfo = rowInfos[focusedElement.row]
          newScrollTop = rowInfo.position + rowInfo.height * focusedElementChop
          scrollParent.scrollTop(newScrollTop)

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

      # Halve the resolution of grid items so the GPU uses less texture memory during transforms. We
      # will record the scale factor so that we can use transform: scale to have them appear at the same
      # correct size.
      downscaleItems = ->
        scale = 3
        $log.debug "Downscaling cards to 1/#{ scale }"
        scaleItems(scale)

      upscaleItems = ->
        if isUpscaleRequired()
          scale = upscaleTo()
          $log.debug "Upscaling cards to 1/#{ scale }"
          scaleItems(scale)
        else
          $log.debug 'Upscaling not performed (zoom level too low)'

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

      selectedCardChanged = (newVal, oldVal) ->
        layoutMode =
          if newVal
            'detail'
          else
            $log.debug 'No cards selected. Displaying cards in grid mode'
            'grid'
        layout()
      scope.$watch('selectedCard', selectedCardChanged)

      cardFilterChanged = (newVal, oldVal) ->
        $log.debug 'Laying out grid (filter change)'
        $timeout ->
          invalidateGridContents()
          layoutNow(true)
        return
      scope.$watch('cardFilter', cardFilterChanged, true)


      # *~*~*~*~ ZOOMING

      scope.$on 'zoomStart', ->
        console.group?('Continuous zoom')
        $timeout -> downscaleItems()
        inContinuousZoom = true

      scope.$on 'zoomEnd', ->
        $log.debug "New zoom level: #{ scope.zoom }"
        upscaleItems()
        inContinuousZoom = false
        console.groupEnd?('Continuous zoom')

      zoomChanged = (newVal) ->
        if inContinuousZoom
          layoutNow()
        else
          layout()

      scope.$watch('zoom', zoomChanged)
  ) # end directive def
