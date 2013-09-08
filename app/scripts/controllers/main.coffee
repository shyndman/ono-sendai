angular.module('deckBuilder')
  .controller('MainCtrl', (cardService, $scope) ->
    $scope.allCards = cardService.cards())
