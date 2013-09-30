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

  CARDS_URL = '/data/cards.json'

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
    card for card in cards when @_matchesFilter(filter, card)

  _matchesFilter: (card, filter) =>
    card.side == filter.side

  _groupCards: ({ primaryGrouping, secondaryGrouping }, cards) =>
    primaryGroups =
      _.chain(cards)
       .groupBy(primaryGrouping)
       .pairs()
       .map((pair) =>
         sortField: pair[0],
         title: @_groupTitle(pair[0]),
         cards: pair[1])
       .sortBy('sortField')
       .value()

    # Build secondary groups
    for group in primaryGroups
      group.cards =
        _.chain(group.cards)
         .groupBy(secondaryGrouping)
         .pairs()
         .map((pair) =>
           title: @_groupTitle(pair[0]),
           sortField: pair[0],
           cards: _.sortBy(pair[1], 'title'))
         .sortBy((subgroup) -> CARD_ORDINALS[subgroup.sortField])
         .value()

    primaryGroups

  _groupTitle: (groupName) ->
    switch groupName
      when 'Agenda', 'Asset', 'Operation', 'Upgrade'
        "#{groupName}s"
      when 'Identity'
        'Identities'
      else
        groupName

angular.module('deckBuilder').service 'cardService', CardService
