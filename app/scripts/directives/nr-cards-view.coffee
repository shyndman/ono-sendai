# This component is responsible for dealing with cards, including user input and layout.

angular.module('deckBuilder')
  .directive('nrCardsView', ($window, $q, $log, $timeout, cssUtils) ->
    restrict: 'E'
    transclude: true
    templateUrl: 'views/directives/nr-cards-view.html'
    scope: {
      cards: '='
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
      # because we swap in lower resolution images before
      inverseDownscaleFactor = 1

      # Returns true if the grid has changed width
      hasGridChangedWidth = ->
        if gridWidth != (newGridWidth = grid.width())
          gridWidth = newGridWidth
          true
        else
          false

      invalidateGridContents = ->
        gridItems = element.find('.grid-item')
        gridHeaders = element.find('.grid-header')
        gridItemsAndHeaders = element.find('.grid-item,.grid-header')

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

        firstItem = $(_.find(items, (item) -> item.classList.contains('grid-item')))
        firstHeader = $(_.find(items, (item) -> item.classList.contains('grid-header')))

        itemSize = getItemSize('item', firstItem)
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
        grid.height(lastRow.position + lastRow.height)

        transitionDuration =
          if element.hasClass('transitioned')
            cssUtils.getTransitionDuration(items.first())
          else
            0
        scrollToFocusedCard(transitionDuration)

        # If we're in transition mode, return a promise that will resolve after
        # transition delay + transition duration.
        if element.hasClass('transitioned')
          $timeout(_.noop, transitionDuration)

      #
      performDetailLayout = ->
        items = gridItems
        if !items.length
          return

        # TODO

        transitionDuration =
          if element.hasClass('transitioned')
            cssUtils.getTransitionDuration(items.first())
          else
            0

        # If we're in transition mode, return a promise that will resolve after
        # transition delay + transition duration.
        if element.hasClass('transitioned')
          $timeout((->), transitionDuration) # Adds a second of fudge

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
          for item, i in items
            item.style.zIndex = len - i
            item.style[transformProperty] =
              "translate3d(#{itemPositions[i].x}px, #{itemPositions[i].y}px, 0)
                     scale(#{Number(scope.zoom) * inverseDownscaleFactor})"

        if !_.isEmpty(headerPositions)
          items = gridHeaders
          len = items.length
          for item, i in items
            item.style.zIndex = len - i
            item.style[transformProperty] =
              "translate3d(#{headerPositions[i].x}px, #{headerPositions[i].y}px, 0)"

        return

      # Watch for resizes that may affect grid size, requiring a re-layout
      windowResized = ->
        if hasGridChangedWidth()
          $log.info 'Laying out grid (grid width change)'
          layoutNow(true)

      $($window).resize(windowResized)

      # *~*~*~*~ SCROLLING

      scrollParent = element.parents('.scrollable').first()

      # NOTE Currently does not animate, unless I figure out a better way to do it. Naive approach
      #      is too jumpy.
      scrollToFocusedCard = (transitionDuration) ->
        if !focusedElement?
          return

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

        # Grab the element
        focusedElement = rowInfo.firstElement
        focusedElementChop = (scrollTop - rowInfo.position) / rowInfo.height

      scrollParent.scroll(_.debounce(scrollChanged, 100))

      # *~*~*~*~ SCALING

      isUpscaleRequired = ->
        scope.zoom > 0.5

      # Halve the resolution of grid items so the GPU uses less texture memory during transitions. We
      # will record the scale factor so that we can use transform: scale to have them appear at the same
      # correct size.
      downscaleItems = ->
        $log.info 'Downscaling cards'
        scaleItems(2)

      upscaleItems = ->
        if isUpscaleRequired()
          $log.info 'Upscaling cards'
          scaleItems(1)
        else
          $log.info 'Upscaling not performed (zoom level too low)'

      scaleItems = (scaleFactor) ->
        if inverseDownscaleFactor is scaleFactor
          $q.when() # Return a resolved promise if we have nothing to do
        else
          inverseDownscaleFactor = scaleFactor

          # Record whether we're marked as transitioned, which we will restore after
          # a defer.
          hasTransitioned = element.hasClass('transitioned')
          element.removeClass('transitioned')

          # Scale the images
          element.toggleClass('downscaled', scaleFactor isnt 1)
          applyItemStyles()

          # Give the browser an opportunity to update the visuals, before restoring
          # the transitioned class.
          if hasTransitioned
            $timeout -> element.toggleClass('transitioned', hasTransitioned)
          else
            $q.when() # Empty promise :)

      # *~*~*~*~ CARDS

      scope.$watch 'selectedCard', (newVal, oldVal) ->
        layoutMode =
          if newVal
            'detail'
          else
            $log.info 'No cards selected. Displaying cards in grid mode'
            'grid'
        layout()

      scope.$watch 'cards', (newVal, oldVal) ->
        $log.info 'Laying out grid (cards change)'
        $timeout ->
          invalidateGridContents()
          layoutNow()

      # *~*~*~*~ ZOOMING

      scope.$on 'zoomStart', ->
        downscaleItems()
        inContinuousZoom = true

      scope.$on 'zoomEnd', ->
        upscaleItems()
        inContinuousZoom = false

      zoomChanged = (newVal) ->
        if inContinuousZoom
          layoutNow()
        else
          layout()

      scope.$watch('zoom', zoomChanged)
  ) # end directive def
