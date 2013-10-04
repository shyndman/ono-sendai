angular.module('deckBuilder')
  .controller('MainCtrl', (cardService, $rootScope) ->

    # Set up filter defaults
    $rootScope.filter =
      side: 'Corp'
      primaryGrouping: 'faction'
      secondaryGrouping: 'type'
      general:
        cost:
          operator: '='
        influenceValue:
          operator: '='
        trashCost:
          operator: '='

      identities:
        enabled: true
        influenceLimit:
          operator: '='
        minimumDeckSize:
          operator: '='

      ice:
        enabled: true
        subroutineCount:
          operator: '='
        strength:
          operator: '='

      assets:
        enabled: true

      operations:
        enabled: true

      agendas:
        enabled: true
        points:
          operator: '='

    # Register a function to change the cards array when filters change.
    $rootScope.$watch('filter', ((filter)->
      cardService.getCards(filter).then((cardGroups) ->
        $rootScope.cardGroups = cardGroups)
    ), true))
