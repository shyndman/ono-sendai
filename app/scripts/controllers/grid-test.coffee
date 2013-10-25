angular.module('deckBuilder')
  .controller('GridTestCtrl', ($scope, $window, cardService, filterDefaults) ->
    $scope.filter = filterDefaults
    $scope.grid = zoom: 0.6
    $scope.broadcastZoomStart = ->
      $scope.$broadcast 'zoomStart'
    $scope.broadcastZoomEnd = ->
      $scope.$broadcast 'zoomEnd'

    cardService.getCards(filterDefaults).then (cardGroups) ->
      $scope.cardsAndGroups =
        _(cardGroups)
          .chain()
          .map((group) ->
            [_.extend(group, isHeader: true), group.cards])
          .flatten()
          .value()
  )
