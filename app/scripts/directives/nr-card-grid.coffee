# NOTES
# * big card looks great at w=340

# HOW THIS THING WORKS
#
#

angular.module('deckBuilder')
  .directive('nrCardGrid', ($window) ->
    div = $('<div></div>')[0]

    # TODO This really feel like it should live in a service or something
    getVendorPropertyName = (prop) ->
      if prop of div.style
        return prop

      prefixes = ['Moz', 'Webkit', 'O', 'ms']
      prop = _.capitalize(prop)

      if prop of div.style
        return prop

      for prefix in prefixes
        vendorProp = prefix + prop
        if vendorProp of div.style
          return vendorProp

    transformProperty = getVendorPropertyName('transform')
    transitionProperty = getVendorPropertyName('transition')

    {
      templateUrl: 'views/directives/nr-card-grid.html'
      scope: {
        cards: '='
        selectedCard: '='
        zoom: '='
      }
      restrict: 'E'
      link: (scope, element, attrs) ->
        minimumGutterWidth = 30
        bottomMargin = 40
        gridWidth = element.width()
        itemPositions = []
        inContinuousZoom = false
        # This is multiplied by scope.zoom to produce the transform:scale value. It is necessary
        # because we swap in lower resolution images before
        inverseDownscaleFactor = 1

        # Returns true if the grid has changed width
        hasGridChangedWidth = ->
          if gridWidth != (newGridWidth = element.width())
            gridWidth = newGridWidth
            true
          else
            false

        gridItems = ->
          element.find('.grid-item')

        # TODO Double check performance on this method. It's likely that we can memoize it if it
        #      ends up being a problem.
        # NOTE Assumes uniform sizing for all grid items (which in our case is not a problem)
        getItemSize = (item) ->
          scaleFactor = scope.zoom * inverseDownscaleFactor

          width:  item.width() * scaleFactor
          height: item.height() * scaleFactor

        layoutNow = ->
          items = gridItems()
          if !items.length
            return

          itemSize   = getItemSize(items.first())
          numColumns = Math.floor((gridWidth + minimumGutterWidth) / (itemSize.width + minimumGutterWidth))
          numGutters = numColumns - 1
          numRows    = Math.ceil(items.length / numColumns)

          gutterWidth  = (gridWidth - (numColumns * itemSize.width)) / numGutters
          colPositions = (i * (itemSize.width + gutterWidth) for i in [0...numColumns])
          rowPositions = (i * (itemSize.height + bottomMargin) for i in [0...numRows])

          element.height(_.last(rowPositions) + itemSize.height)

          for i in [0...items.length]
            itemPositions[i] =
              x: colPositions[i % numColumns],
              y: rowPositions[Math.floor(i / numColumns)]

          applyItemStyles()

        # We provide a debounced version, so we don't layout too much
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
            layout()

        $($window).resize(windowResized)

        scope.$watch('cards', (newVal, oldVal) ->
          console.info 'Laying out grid (cards change)'
          layout()
        )

        # Halve the resolution of grid items so the GPU uses less texture memory during transitions. We
        # will record the scale factor so that we can use transform: scale to have them appear at the same
        # correct size.
        downscaleItems = ->
          if inverseDownscaleFactor isnt 1
            return

          element.addClass('downscaled')
          inverseDownscaleFactor = 2

        upscaleImages = ->
          if inverseDownscaleFactor is 1
            return

          element.removeClass('downscaled')
          inverseDownscaleFactor = 1

        # *~*~*~*~ ZOOMING

        scope.$on 'zoomStart', ->
          element.removeClass('transitioned')
          downscaleItems()
          applyItemStyles()
          inContinuousZoom = true

        scope.$on 'zoomEnd', ->
          inContinuousZoom = false
          upscaleImages()
          applyItemStyles()
          _.defer -> element.addClass('transitioned')

        zoomChanged = (newVal) ->
          console.info 'Changing item sizes (zoom change)'
          if inContinuousZoom
            layoutNow()
          else
            layout()

        scope.$watch('zoom', zoomChanged)
    }
  ) # end directive def
