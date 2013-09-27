angular.module('deckBuilder')
  .controller('MainCtrl', (cardService, $scope) ->

    # Set up filter defaults
    $scope.filter =
      side: 'Corp'
      primaryGrouping: 'faction'
      secondaryGrouping: 'type'

    # Register a function to change the cards array when filters change.
    $scope.$watch('filter', ((filter)->
      $scope.cards = cardService.getCards(filter)
    ), true))
