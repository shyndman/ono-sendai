angular.module('deckBuilder')
  .constant('filterDefinitions',
    side: 'Corp'
    primaryGrouping: 'faction'
    secondaryGrouping: 'type'
    general:
      enabled: true
      cost:
        operator: '='
      influenceValue:
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

    assets:
      enabled: true
      trashCost:
        operator: '='

    operations:
      enabled: true

    upgrades:
      enabled: true
      trashCost:
        operator: '='
  )
