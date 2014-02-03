angular.module('onoSendai')
  # Contains default values for the filters manipulated by the user interface
  .factory('queryArgDefaults', (userPreferences) ->
    get: ->
      side: 'Corp'
      search: ''
      activeGroup: 'general'
      groupings: [ 'faction', 'type' ]
      fieldFilters:
        faction:
          'Corp: Haas-Bioroid': true
          'Corp: Jinteki': true
          'Corp: NBN': true
          'Corp: Weyland Consortium': true
          'Corp: Neutral': true
          'Runner: Anarch': true
          'Runner: Criminal': true
          'Runner: Shaper': true
          'Runner: Neutral': true
        subtype: null
        cost:
          operator: '='
        factionCost:
          operator: '='
        setname: null
        illustrator: null
        showSpoilers: userPreferences.showSpoilers() ? true
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
        memoryUnits:
          operator: '='
        baseLink:
          operator: '='
  )
  # Describes the ordering, appearance and functionality of the filter sidebar
  .constant('filterUI',
    [
      {
        name: 'general'
        display: 'general'
        fieldFilters: [
          {
            name: 'faction'
            type: 'faction'
            icon: 'faction'
            side:
              corp: [
                { name: 'Haas-Bioroid',       abbr: 'HB',  model: 'Corp: Haas-Bioroid' }
                { name: 'Jinteki',            abbr: 'J',   model: 'Corp: Jinteki' }
                { name: 'NBN',                abbr: 'NBN', model: 'Corp: NBN' }
                { name: 'Weyland Consortium', abbr: 'W',   model: 'Corp: Weyland Consortium' }
                { name: 'Neutral',            abbr: 'N',   model: 'Corp: Neutral' }
              ]
              runner: [
                { name: 'Anarch',             abbr: 'A',   model: 'Runner: Anarch' }
                { name: 'Criminal',           abbr: 'C',   model: 'Runner: Criminal' }
                { name: 'Shaper',             abbr: 'S',   model: 'Runner: Shaper' }
                { name: 'Neutral',            abbr: 'N',   model: 'Runner: Neutral' }
              ]
          }
          {
            name: 'search'
            type: 'search'
            placeholder: 'Keyword Search'
            icon: 'search'
          }
          {
            name: 'subtype'
            type: 'inSet'
            placeholder: 'Subtype'
            icon: 'subtype'
            source: 'subtypes'
          }
          {
            name: 'cost'
            type: 'numeric'
            placeholder: 'Cost'
            icon: 'credit'
          }
          {
            name: 'factionCost'
            type: 'numeric'
            placeholder: 'Influence'
            icon: 'influence'
            max: 5
          }
          {
            name: 'setname'
            type: 'inSet'
            placeholder: 'Set'
            icon: 'set'
            source: 'sets'
          }
          {
            name: 'illustrator'
            type: 'inSet'
            placeholder: 'Illustrator'
            icon: 'illustrator'
            source: 'illustrators'
          }
        ]
      },
      {
        name: 'identity'
        display: 'identities'
        hiddenGeneralFields:
          cost: true
          factionCost: true
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
          {
            side: 'Runner'
            name: 'baseLink'
            type: 'numeric'
            placeholder: 'Base Link'
            icon: 'link-strength'
          }
        ]
      },
      {
        name: 'agenda'
        display: 'agendas'
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
        name: 'asset'
        display: 'assets'
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
        name: 'operation'
        display: 'operations'
        side: 'Corp'
      },
      {
        name: 'ice'
        display: 'ice'
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
        name: 'upgrade'
        display: 'upgrades'
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
        name: 'event'
        display: 'events'
        side: 'Runner'
      },
      {
        name: 'hardware'
        display: 'hardware'
        side: 'Runner'
      },
      {
        name: 'program'
        display: 'programs'
        side: 'Runner'
        fieldFilters: [
          {
            name: 'memoryUnits'
            type: 'numeric'
            placeholder: 'Memory Units'
            icon: 'memory-unit'
          }
        ]
      },
      {
        name: 'resource'
        display: 'resources'
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
          subtype: 'boolSet'
          cardField: 'faction'
        search:
          type: 'search'
        cost:
          type: 'numeric'
          cardField: [ 'advancementcost', 'cost' ]
        factionCost:
          type: 'numeric'
          cardField: 'factioncost'
        setname:
          type: 'cardSet'
          cardField: 'setname'
        subtype:
          type: 'inSet'
          cardField: 'subtypesSet'
        illustrator:
          type: 'match'
          cardField: 'illustratorId'
        showSpoilers:
          type: 'showSpoilers'
    }
    identity: {
      cardType: 'Identity'
      excludedGeneralFields:
        cost: true
        factionCost: true
      fieldFilters:
        influenceLimit:
          type: 'numeric'
          cardField: 'influencelimit'
        minimumDeckSize:
          type: 'numeric'
          cardField: 'minimumdecksize'
        baseLink:
          type: 'numeric'
          cardField: 'baselink'
          inclusionPredicate: (queryArgs) -> queryArgs.side is 'Runner'
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
    agenda: {
      cardType: 'Agenda'
      fieldFilters:
        points:
          type: 'numeric'
          cardField: 'agendapoints'
    }
    asset: {
      cardType: 'Asset'
      fieldFilters:
        assetTrashCost:
          type: 'numeric'
          cardField: 'trash'
    }
    operation: {
      cardType: 'Operation'
    },
    upgrade: {
      cardType: 'Upgrade'
      fieldFilters:
        upgradeTrashCost:
          type: 'numeric'
          cardField: 'trash'
    }
    event: {
      cardType: 'Event'
    }
    hardware: {
      cardType: 'Hardware'
    }
    program: {
      cardType: 'Program'
      fieldFilters:
        memoryUnits:
          type: 'numeric'
          cardField: 'memoryunits'
    }
    resource: {
      cardType: 'Resource'
    }
  )
  .constant('groupingUI',
    [
      {
        display: 'Faction'
        groupings: [ 'faction', 'type' ]
      }
      {
        display: 'Type'
        groupings: [ 'type' ]
      }
      {
        display: 'Cost'
        groupings: [ 'cost' ]
      }
      {
        display: 'Influence'
        groupings: [ 'factioncost' ]
      }
      {
        display: 'Set'
        groupings: [ 'setname' ]
      }
      {
        display: 'Illus.'
        groupings: [ 'illustrator' ]
      }
    ]
  )
