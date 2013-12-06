angular.module('onoSendai')
  .controller('CardViewCtrl', ->

  )
  .directive('cardView', ->
    templateUrl: '/views/directives/nr-card-view.html'
    restrict: 'E'
    controller: 'CardViewCtrl'
    scope: {
      card: '='
      queryResult: '='
    }
    link: (scope, element, attrs) ->
        # performDetailLayout = ->
        #   items = gridItems
        #   if !items.length
        #     return

        #   # Ensure that we aren't scrolling.
        #   setScrollerOverflow('hidden')

        #   # Work out base Y coordinate
        #   baseY = scrollTop
        #   baseY += 55
        #   nextPrevY = baseY + 8
        #   nextPrevW = 160

        #   selEle =
        #     if !scope.selection
        #       null
        #     else
        #       gridItemsById[scope.selection.id]

        #   for item, i in gridHeaders
        #     layout = headerLayouts[i] ?= {}
        #     layout.opacity = 0

        #   skipCount = 0
        #   for item, i in gridItems
        #     if skipCount > 0
        #       skipCount--
        #       continue

        #     layout = itemLayouts[i] ?= {}
        #     layout.opacity = 0
        #     layout.classes = hidden: true

        #     if item == selEle
        #       numNextPrev = 2
        #       selLeft = (containerWidth - 600) / 2 + 10
        #       selRight = selLeft + 470

        #       _.extend layout,
        #         zoom: 0.95
        #         classes:
        #           'current': true
        #         x: selLeft # TODO Pull the literal from CSS
        #         y: baseY
        #         rotationY: 0

        #       for j in [1..numNextPrev]
        #         if i - j >= 0
        #           _.extend itemLayouts[i - j],
        #             zoom: 0.7
        #             classes:
        #               'prev': true
        #             x: selLeft - (j * 30) - nextPrevW
        #             y: nextPrevY
        #           itemLayouts[i - j].classes["prev-#{j}"] = true

        #       for j in [1..numNextPrev]
        #         itemLayouts[i + j] ?= {} # XXX Barf. Sloppy.
        #         if i + j < gridItems.length
        #           _.extend itemLayouts[i + j],
        #             zoom: 0.7
        #             classes:
        #               'next': true
        #             x: selRight + ((j - 1) * 30)
        #             y: nextPrevY
        #           itemLayouts[i + j].classes["next-#{j}"] = true

        #       skipCount = 2

        #   applyItemStyles()
        #   return

  )
