angular.module('deckBuilder')
  .controller('GridTestCtrl', (cardService, $scope, $window) ->
    $scope.grid = zoom: 0.6
    $scope.broadcastZoomStart = ->
      $scope.$broadcast 'zoomStart'
    $scope.broadcastZoomEnd = ->
      $scope.$broadcast 'zoomEnd'

    cardService._cardsPromise.then (cards) ->
      $scope.cards = cards
  )
