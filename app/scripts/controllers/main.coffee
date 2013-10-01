angular.module('deckBuilder')
  .controller('MainCtrl', (cardService, $rootScope) ->

    # Set up filter defaults
    $rootScope.filter =
      side: 'Corp'
      primaryGrouping: 'faction'
      secondaryGrouping: 'type'

    # Register a function to change the cards array when filters change.
    $rootScope.$watch('filter', ((filter)->
      $rootScope.cards = cardService.getCards(filter)
    ), true))
