angular.module('deckBuilder')
  .controller('MainCtrl', (cardService, $rootScope) ->
    # Register a function to change the cards array when filters change.
    $rootScope.$watch('filter', ((filter)->
      cardService.getCards(filter).then((cardGroups) ->
        $rootScope.cardGroups = cardGroups)
    ), true))
