angular.module('deckBuilder')
  # Contains default values for the filters manipulated by the user interface
  .value('filterDefaults',
    side: 'Corp'
    primaryGrouping: 'faction'
    secondaryGrouping: 'type'
    fieldFilters:
      cost:
        operator: '='
      influenceValue:
        operator: '='
      influenceLimit:
        operator: '='
      minimumDeckSize:
        operator: '='
      points:
        operator: '='
      assetTrashCost:
        operator: '='
      subroutineCount:
        operator: '='
      iceStrength:
        operator: '='
      influence:
        operator: '='
      upgradeTrashCost:
        operator: '='
  )
  # Describes the ordering, appearance and functionality of the filter sidebar
  .constant('filterUI',
    [
      {
        name: 'general'
        fieldFilters: [
          {
            name: 'cost'
            placeholder: 'Cost'
            icon: 'credit'
          }
          {
            name: 'influenceValue'
            placeholder: 'Influence'
            icon: 'influence'
          }
        ]
      },
      {
        name: 'identities'
        hideGeneral: true
        fieldFilters: [
          {
            name: 'influenceLimit'
            placeholder: 'Influence Limit'
            icon: 'influence'
          }
          {
            name: 'minimumDeckSize'
            placeholder: 'Min. Deck Size'
            icon: 'minimum-deck-size'
          }
        ]
      },
      {
        name: 'agendas'
        fieldFilters: [
          {
            name: 'points'
            placeholder: 'Agenda Points'
            icon: 'agenda-point'
          }
        ]
      },
      {
        name: 'assets'
        fieldFilters: [
          {
            name: 'assetTrashCost'
            placeholder: 'Trash Cost'
            icon: 'trash-cost'
          }
        ]
      },
      {
        name: 'operations'
      },
      {
        name: 'ice'
        fieldFilters: [
          {
            name: 'subroutineCount'
            placeholder: '# Subroutines'
            icon: 'subroutine'
          }
          {
            name: 'iceStrength'
            placeholder: 'Strength'
            icon: 'strength'
          }
        ]
      },
      {
        name: 'upgrades'
        fieldFilters: [
          {
            name: 'upgradeTrashCost'
            placeholder: 'Trash Cost'
            icon: 'trash-cost'
          }
        ]
      }
    ]
  )
  # Filter descriptors describe how the card service should interpret filter information coming from the user interface.
  .constant('filterDescriptors',
    general: {
      cardType: 'general'
      fieldFilters:
        cost:
          type: 'numeric'
          cardField: [ 'advancementcost', 'cost' ]
        influenceValue:
          type: 'numeric'
          cardField: 'factioncost'
    }
    identities: {
      cardType: 'Identity'
      excludeGeneral: true
      fieldFilters:
        influenceLimit:
          type: 'numeric'
          cardField: 'influencelimit'
        minimumDeckSize:
          type: 'numeric'
          cardField: 'minimumdecksize'
    }
    ice: {
      cardType: 'ICE'
      fieldFilters:
        subroutineCount:
          type: 'numeric'
          cardField: 'subroutinecount'
        iceStrength:
          type: 'numeric'
          cardField: 'strength'
    }
    agendas: {
      cardType: 'Agenda'
      fieldFilters:
        points:
          type: 'numeric'
          cardField: 'agendapoints'
    }
    assets: {
      cardType: 'Asset'
      fieldFilters:
        assetTrashCost:
          type: 'numeric'
          cardField: 'trash'
    }
    operations: {
      cardType: 'Operation'
    },
    upgrades:   {
      cardType: 'Upgrade'
      fieldFilters:
        upgradeTrashCost:
          type: 'numeric'
          cardField: 'trash'
    })
