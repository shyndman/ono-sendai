# This component is responsible for dealing with cards, including user input and layout.

angular.module('deckBuilder')
  .directive('nrCardsView', ($window, $q, $timeout, cssUtils) ->
    restrict: 'E'
    templateUrl: 'views/directives/nr-cards-view.html'
    scope: {
      cards: '='
      selectedCard: '='
      zoom: '='
    }
    link: (scope, element, attrs) ->
      mode = 'grid'
      minimumGutterWidth = 30
      bottomMargin = 40
      transformProperty = cssUtils.getVendorPropertyName('transform')
      grid = element.find('.grid')
      gridWidth = grid.width()
      inContinuousZoom = false
      itemSize = null
      focusedCardIdx = null
      focusedCardOverflow = null # Percentage of the focused card above the fold
      colPositions = []
      rowPositions = []
      itemPositions = []

      # This is multiplied by scope.zoom to produce the transform:scale value. It is necessary
      # because we swap in lower resolution images before
      inverseDownscaleFactor = 1

      # Determine which card is in the top left, so that we can keep it focused through zooming
      scrollChanged = ->
        if inContinuousZoom
          return

        scrollTop = element.scrollTop()
        topVisibleRow = Math.max(_.sortedIndex(rowPositions, scrollTop) - 1, 0)
        focusedCardIdx = topVisibleRow * colPositions.length
        focusedCardOverflow = (scrollTop - rowPositions[topVisibleRow]) / itemSize.height

      element.scroll(_.debounce(scrollChanged, 100))

      # NOTE Currently does not animate, unless I figure out a better way to do it. Naive approach
      #      is too jumpy.
      scrollToFocusedCard = (transitionDuration) ->
        row = Math.floor(focusedCardIdx / colPositions.length)
        newScrollTop = rowPositions[row] + itemSize.height * focusedCardOverflow
        element.scrollTop(newScrollTop)

      # Returns true if the grid has changed width
      hasGridChangedWidth = ->
        if gridWidth != (newGridWidth = grid.width())
          gridWidth = newGridWidth
          true
        else
          false

      gridItems = -> element.find('.grid-item')

      # NOTE Assumes uniform sizing for all grid items (which in our case is not a problem)
      getItemSize = (item) ->
        scaleFactor = scope.zoom * inverseDownscaleFactor

        {
          width:  item.width() * scaleFactor
          height: item.height() * scaleFactor
        }

      # Returns a promise that is resolved when any transitions complete, or undefined if there is no
      # transition.
      performGridLayout = ->
        items = gridItems()
        if !items.length
          return

        itemSize   = getItemSize(items.first())
        numColumns = Math.floor((gridWidth + minimumGutterWidth) / (itemSize.width + minimumGutterWidth))
        numGutters = numColumns - 1
        numRows    = Math.ceil(items.length / numColumns)

        gutterWidth  = (gridWidth - (numColumns * itemSize.width)) / numGutters
        colPositions = (i * (itemSize.width + gutterWidth)   for i in [0...numColumns])
        rowPositions = (i * (itemSize.height + bottomMargin) for i in [0...numRows])

        for i in [0...items.length]
          itemPositions[i] =
            x: colPositions[i % numColumns],
            y: rowPositions[Math.floor(i / numColumns)]

        applyItemStyles()
        grid.height(_.last(rowPositions) + itemSize.height)

        transitionDuration =
          if element.hasClass('transitioned')
            cssUtils.getTransitionDuration(items.first())
          else
            0
        scrollToFocusedCard(transitionDuration)

        # If we're in transition mode, return a promise that will resolve after
        # transition delay + transition duration.
        if element.hasClass('transitioned')
          $timeout((->), transitionDuration + 1000) # Adds a second of fudge

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
          if mode is 'grid'
            performGridLayout
          else
            performDetailLayout

        scalePromise
          .then(layoutFn)
          .then(->
            if scaleImages
              upscaleItems())

      # We provide a debounced version, so we don't layout too much during user input
      layout = _.debounce(layoutNow, 200)

      applyItemStyles = ->
        if _.isEmpty(itemPositions)
          return

        items = gridItems()
        len = items.length
        for item, i in items
          item.style.zIndex = len - i
          item.style[transformProperty] =
            "translate3d(#{itemPositions[i].x}px, #{itemPositions[i].y}px, 0)
                   scale(#{Number(scope.zoom) * inverseDownscaleFactor})"
        return

      # Watch for resizes that may affect grid size, requiring a re-layout
      windowResized = ->
        if hasGridChangedWidth()
          console.info 'Laying out grid (grid width change)'
          layout(true)

      $($window).resize(windowResized)

      scope.$watch('cards', (newVal, oldVal) ->
        console.info 'Laying out grid (cards change)'
        layout()
      )

      # Halve the resolution of grid items so the GPU uses less texture memory during transitions. We
      # will record the scale factor so that we can use transform: scale to have them appear at the same
      # correct size.
      downscaleItems = ->
        console.info 'Downscaling cards'
        scaleItems(2)

      upscaleItems = ->
        console.info 'Upscaling cards'
        scaleItems(1)

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
          $timeout -> element.toggleClass('transitioned', hasTransitioned)

      # *~*~*~*~ ZOOMING

      scope.$on 'zoomStart', ->
        downscaleItems()
        inContinuousZoom = true

      scope.$on 'zoomEnd', ->
        upscaleItems()
        inContinuousZoom = false

      zoomChanged = (newVal) ->
        console.info 'Changing item sizes (zoom change)'
        if inContinuousZoom
          layoutNow()
        else
          layout()

      scope.$watch('zoom', zoomChanged)
  ) # end directive def
