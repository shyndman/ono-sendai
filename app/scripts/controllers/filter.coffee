'use strict'

angular.module('deckBuilder')
  .controller 'FilterCtrl', ($rootScope) ->

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

      agendas:
        enabled: true
        points:
          operator: '='

      assets: enabled: true
      operations: enabled: true
      upgrades: enabled: true

