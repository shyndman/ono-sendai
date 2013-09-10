angular.module('deckBuilder')
  .controller('MainCtrl', (cardService, $scope) ->
    $scope.filter = side: 'Corp'
    cardService.cards((cards) ->
      $scope.allCards = cards))
