angular.module('deckBuilder')
  # Contains default values for the filters manipulated by the user interface
  .value('filterDefaults',
    side: 'Corp'
    groupings: [ 'faction', 'type' ]
    fieldFilters:
      faction:
        haasBioroid: true
        jinteki: true
        nbn: true
        weyland: true
        corpNeutral: true
        anarch: true
        criminal: true
        shaper: true
        runnerNeutral: true
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
            name: 'side'
            type: 'side'
            icon: 'side'
          }
          {
            name: 'faction'
            type: 'faction'
            icon: 'faction'
            faction:
              corp: [
                {
                  name: 'Haas-Bioroid'
                  abbr: 'HB'
                  model: 'haasBioroid'
                }
                {
                  name: 'Jinteki'
                  abbr: 'J'
                  model: 'jinteki'
                }
                {
                  name: 'NBN'
                  abbr: 'NBN'
                  model: 'nbn'
                }
                {
                  name: 'Weyland Consortium'
                  abbr: 'W'
                  model: 'weyland'
                }
                {
                  name: 'Neutral'
                  abbr: 'N'
                  model: 'corpNeutral'
                }
              ]
              runner: [
                {
                  name: 'Anarch'
                  abbr: 'A'
                  model: 'anarch'
                }
                {
                  name: 'Criminal'
                  abbr: 'C'
                  model: 'criminal'
                }
                {
                  name: 'Shaper'
                  abbr: 'S'
                  model: 'shaper'
                }
                {
                  name: 'Neutral'
                  abbr: 'N'
                  model: 'runnerNeutral'
                }
              ]
          }
          {
            name: 'cost'
            type: 'numeric'
            placeholder: 'Cost'
            icon: 'credit'
          }
          {
            name: 'influenceValue'
            type: 'numeric'
            placeholder: 'Influence'
            icon: 'influence'
          }
        ]
      },
      {
        name: 'identities'
        hiddenGeneralFields:
          cost: true
          influenceValue: true
        fieldFilters: [
          {
            name: 'influenceLimit'
            type: 'numeric'
            placeholder: 'Influence Limit'
            icon: 'influence'
          }
          {
            name: 'minimumDeckSize'
            type: 'numeric'
            placeholder: 'Min. Deck Size'
            icon: 'minimum-deck-size'
          }
        ]
      },
      {
        name: 'agendas'
        side: 'Corp'
        fieldFilters: [
          {
            name: 'points'
            type: 'numeric'
            placeholder: 'Agenda Points'
            icon: 'agenda-point'
          }
        ]
      },
      {
        name: 'assets'
        side: 'Corp'
        fieldFilters: [
          {
            name: 'assetTrashCost'
            type: 'numeric'
            placeholder: 'Trash Cost'
            icon: 'trash-cost'
          }
        ]
      },
      {
        name: 'operations'
        side: 'Corp'
      },
      {
        name: 'ice'
        side: 'Corp'
        fieldFilters: [
          {
            name: 'subroutineCount'
            type: 'numeric'
            placeholder: '# Subroutines'
            icon: 'subroutine'
          }
          {
            name: 'iceStrength'
            type: 'numeric'
            placeholder: 'Strength'
            icon: 'strength'
          }
        ]
      },
      {
        name: 'upgrades'
        side: 'Corp'
        fieldFilters: [
          {
            name: 'upgradeTrashCost'
            type: 'numeric'
            placeholder: 'Trash Cost'
            icon: 'trash-cost'
          }
        ]
      },
      {
        name: 'events'
        side: 'Runner'
      },
      {
        name: 'hardware'
        side: 'Runner'
      },
      {
        name: 'programs'
        side: 'Runner'
      },
      {
        name: 'resources'
        side: 'Runner'
      }
    ]
  )
  # Filter descriptors describe how the card service should interpret filter information coming from the user interface.
  .constant('filterDescriptors',
    general: {
      fieldFilters:
        faction:
          type: 'inSet'
          cardField: 'faction'
          modelMappings:
            'Corp: Haas-Bioroid': 'haasBioroid'
            'Corp: Jinteki': 'jinteki'
            'Corp: NBN': 'nbn'
            'Corp: Weyland Consortium': 'weyland'
            'Corp: Neutral': 'corpNeutral'
            'Runner: Anarch': 'anarch'
            'Runner: Criminal': 'criminal'
            'Runner: Shaper': 'shaper'
            'Runner: Neutral': 'runnerNeutral'
        cost:
          type: 'numeric'
          cardField: [ 'advancementcost', 'cost' ]
        influenceValue:
          type: 'numeric'
          cardField: 'factioncost'
    }
    identities: {
      cardType: 'Identity'
      excludedGeneralFields:
        cost: true
        influenceValue: true
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
    upgrades: {
      cardType: 'Upgrade'
      fieldFilters:
        upgradeTrashCost:
          type: 'numeric'
          cardField: 'trash'
    }
    events: {
      cardType: 'Event'
    }
    hardware: {
      cardType: 'Hardware'
    }
    programs: {
      cardType: 'Program'
    }
    resources: {
      cardType: 'Resource'
    })
