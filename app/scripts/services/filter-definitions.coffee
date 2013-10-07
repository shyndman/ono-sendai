angular.module('deckBuilder')
  # Describes the filter user interface structure, as well as defaults for controls.
  .value('filterDefaults',
    side: 'Corp'
    primaryGrouping: 'faction'
    secondaryGrouping: 'type'
    filterGroups: [
      {
        name: 'general'
        fieldFilters: [
          {
            name: 'cost'
            operator: '='
            placeholder: 'Cost'
            icon: 'credit'
          }
          {
            name: 'influenceValue'
            operator: '='
            placeholder: 'Influence'
            icon: 'influence'
          }
        ]
      },
      {
        name: 'identities'
        fieldFilters: [
          {
            name: 'influenceLimit'
            operator: '='
            placeholder: 'Influence Limit'
            icon: 'influence'
          }
          {
            name: 'minimumDeckSize'
            operator: '='
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
            operator: '='
            placeholder: 'Agenda Points'
            icon: 'agenda-point'
          }
        ]
      },
      {
        name: 'assets'
        fieldFilters: [
          {
            name: 'trashCost'
            operator: '='
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
            operator: '='
            placeholder: '# Subroutines'
            icon: 'subroutine'
          }
          {
            name: 'strength'
            operator: '='
            placeholder: 'Strength'
            icon: 'strength'
          }
        ]
      },
      {
        name: 'upgrades'
        fieldFilters: [
          {
            name: 'trashCost'
            operator: '='
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
        strength:
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
        trashCost:
          type: 'numeric'
          cardField: 'trash'
    }
    operations: {
      cardType: 'Operation'
    },
    upgrades:   {
      cardType: 'Upgrade'
      fieldFilters:
        trashCost:
          type: 'numeric'
          cardField: 'trash'
    })
