# A service for loading, filtering and grouping cards.
class CardService
  CARD_ORDINALS =
    Identity:  0
    # Runner
    Event:     1
    Hardware:  2
    Program:   3
    Resource:  4
    # Corp
    Agenda:    5
    Asset:     6
    Operation: 7
    ICE:       8
    Upgrade:   9

  # Describes how various type-specific filters map onto the underlying cards.json datastructure,
  # and what filter operations should be performed.
  TYPE_FILTER_MAPPING =
    identities: {
      cardType: 'Identity'
      influenceLimit:
        type: 'numeric'
        cardField: 'influencelimit'
      minimumDeckSize:
        type: 'numeric'
        cardField: 'minimumdecksize'
    }
    ice: {
      cardType: 'ICE'
      subroutineCount:
        type: 'numeric'
        cardField: 'subroutinecount'
      strength:
        type: 'numeric'
        cardField: 'strength'
    }
    agendas: {
      cardType: 'Agenda'
      points:
        type: 'numeric'
        cardField: 'agendapoints'
    }
    assets: {
      cardType: 'Asset'
    }
    operations: {
      cardType: 'Operation'
    }
    upgrades: {
      cardtype: 'Upgrade'
    }


  CARDS_URL = '/data/cards.json'

  comparisonOperators: ['=', '<', '≤', '>', '≥']

  constructor: ($http, @searchService) ->
    @searchService = searchService
    @_cards = []

    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .then(({ data: @_cards, status, headers }) =>
        window.cards = @_cards
        @searchService.indexCards(@_cards)
        @_cards)

  getCards: (filter = {}) ->
    @_cardsPromise
      .then(_.partial(@_searchCards, filter))
      .then(_.partial(@_filterCards, filter))
      .then(_.partial(@_groupCards, filter))

  _searchCards: ({ search }) =>
    if _.trim(search).length > 0
      @searchService.search(search)
    else
      @_cards

  _filterCards: (filter, cards) =>
    enabledTypes = @_enabledTypes(filter)
    card for card in cards when @_matchesFilter(card, filter, enabledTypes: enabledTypes)

  _matchesFilter: (card, filter, { enabledTypes }) =>
    return (card.side == filter.side) and
           (if enabledTypes? then enabledTypes[card.type] else true)

  _enabledTypes: (filter) =>
    _.object([ descriptor.cardType, filter[name].enabled ] for name, descriptor of TYPE_FILTER_MAPPING)

  _groupCards: ({ primaryGrouping, secondaryGrouping }, cards) =>
    primaryGroups =
      _.chain(cards)
       .groupBy(primaryGrouping)
       .pairs()
       .map((pair) =>
         id: pair[0],
         sortField: pair[0],
         title: @_groupTitle(pair[0]),
         subgroups: pair[1])
       .sortBy('sortField')
       .value()

    # Build secondary groups
    for group in primaryGroups
      group.subgroups =
        _.chain(group.subgroups)
         .groupBy(secondaryGrouping)
         .pairs()
         .map((pair) =>
           id: "#{group.id}-#{pair[0]}",
           title: @_groupTitle(pair[0]),
           sortField: pair[0],
           cards: _.sortBy(pair[1], 'title'))
         .sortBy((subgroup) -> CARD_ORDINALS[subgroup.sortField])
         .value()

    primaryGroups

  _groupTitle: (groupName) ->
    # TODO This needs a rethink/refactor
    switch groupName
      when 'Agenda', 'Asset', 'Operation', 'Upgrade', 'Event', 'Program', 'Resource'
        "#{groupName}s"
      when 'Identity'
        'Identities'
      else
        groupName

angular.module('deckBuilder').service 'cardService', CardService
