# A service for loading, filtering and grouping cards.
class CardService
  CARDS_URL = 'data/cards.json'

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

  SET_ORDINALS =
    'Core Set':              0
    'What Lies Ahead':       1 # Dec '12
    'Trace Amount':          2 # Jan '13
    'Cyber Exodus':          3 # Feb '13
    'A Study in Static':     4 # Mar '13
    "Humanity's Shadow":     5 # May '13
    'Future Proof':          6 # June '13
    'Creation and Control':  7 # July '13
    'Opening Moves':         8 # Sept '13
    'Second Thoughts':       9 # Nov '13
    'Mala Tempora':         10 # Dec '13
    'True Colors':          11 # Jan '13
    'Fear and Loathing':    12 # Feb '13
    'Double Time':          13 # ?

  OPERATORS = {
    'and': (predicates, args...) ->
      for p in predicates
        if not p(args...)
          return false
      true
    '=': (a, b) -> a is b
    '<': (a, b) -> a < b
    '≤': (a, b) -> a <= b
    '>': (a, b) -> a > b
    '≥': (a, b) -> a >= b
  }

  comparisonOperators: ['=', '<', '≤', '>', '≥']

  constructor: ($http, @searchService, @filterDescriptors) ->
    @searchService = searchService
    @_cards = []

    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .then(({ data: @_cards, status, headers }) =>
        window.cards = @_cards # DEBUG
        @searchService.indexCards(@_cards)
        @_augmentCards(@_cards)
        @_cards)

  getCards: (filterArgs = {}) ->
    @_cardsPromise
      .then(_.partial(@_searchCards, filterArgs))
      .then(_.partial(@_filterCards, filterArgs))
      .then(_.partial(@_groupCards, filterArgs))
      .catch((e) -> console.error(e)) # TODO Robustify

  _searchCards: ({ search }) =>
    if _.trim(search).length > 0
      @searchService.search(search)
    else
      @_cards

  _filterCards: (filterArgs, cards) =>
    enabledTypes = @_enabledTypes(filterArgs)
    filterFn = @_buildFilterFunction(filterArgs, enabledTypes)
    card for card in cards when @_matchesFilter(card, filterArgs, { enabledTypes, filterFn })

  # Returns true if the provided card matches
  _matchesFilter: (card, filterArgs, { enabledTypes, filterFn }) =>
    return (card.side is filterArgs.side) and
           (if enabledTypes? then enabledTypes[card.type] else true) and
           (if filterFn? then filterFn(card) else true)

  # Returns a map of card type names (as they appear in cards.json) to boolean values, indicating whether
  # they should be returned (true) or not (false).
  _enabledTypes: (filterArgs) =>
    selName = filterArgs.activeGroup?.name
    if !selName? or selName is 'general'
      null
    else
      cardType = @filterDescriptors[selName].cardType
      enabledTypes = {}
      enabledTypes[cardType] = true
      enabledTypes

  _buildFilterFunction: (filterArgs, enabledTypes) =>
    filterGroups = ['general']
    filterGroups.push filterArgs.activeGroup.name if filterArgs.activeGroup
    excludeFields = filterArgs.activeGroup?.excludedGeneralFields? || {}

    filters = _(filterGroups)
      .chain()
      .map((name) => @filterDescriptors[name])
      .filter((group) => group.fieldFilters?)
      .pluck('fieldFilters')
      .map((fields) =>
        _.map(fields, (field, name) =>
          if !excludeFields[name]?
            @_buildFilter(field, filterArgs.fieldFilters[name])))
      .flatten()
      .compact()
      .value()

    if _.isEmpty(filters)
      null
    else
      _.partial(OPERATORS.and, filters)

  _buildFilter: (filterDesc, filterArg) ->
    switch filterDesc.type
      when 'numeric'
        if filterArg.value? and filterArg.operator?
          @_buildNumericFilter(filterDesc, filterArg)
      when 'inSet'
        @_buildInSetFilter(filterDesc, filterArg)
      else
        console.warn "Unknown filter type: #{ filterDesc.type }"

  # TODO document
  _buildNumericFilter: (filterDesc, filterArg) ->
    (card) ->
      cardFields =
        if _.isArray(filterDesc.cardField)
          filterDesc.cardField
        else
          [filterDesc.cardField]

      for field in cardFields when card[field]?
        fieldVal = card[field]
        return OPERATORS[filterArg.operator](fieldVal, filterArg.value)

      false

  # TODO document
  _buildInSetFilter: (filterDesc, filterArg) ->
    (card) ->
      # XXX Special case, to avoid ambiguity between the two Neutral factions (Runner/Corp).
      #     This could probably be accomplished differently, but quick and dirty for now.
      fieldVal =
        if filterDesc.cardField is 'faction'
          "#{ card.side }: #{ card.faction }"
        else
          card[filterDesc.cardField]

      # Now that we have the card value, we have to map it to the boolean "set" field in the filter
      # argument.
      filterArg[filterDesc.modelMappings[fieldVal]]

  _groupCards: ({ groupings }, cards) =>
    sortFns =
      _(groupings)
        .chain()
        .concat(['title'])
        .map(@_sortFnFor)
        .value()

    _(cards)
      .chain()
      .multiSort(sortFns...)
      .groupBy((card) -> _.map(groupings, (g) -> card[g]))
      .pairs()
      .map((pair) =>
        id: pair[0].replace(/,/g, ' ').toLowerCase(),
        title: pair[0].split(',')
        cards: pair[1])
      .value()

  _sortFnFor: (fieldName) =>
    switch fieldName
      when 'type'
        (a, b) -> CARD_ORDINALS[a.type] - CARD_ORDINALS[b.type]
      when 'cost', 'factioncost'
        (a, b) -> a[fieldName] - b[fieldName]
      when 'setname'
        (a, b) -> SET_ORDINALS[a.setname] - SET_ORDINALS[b.setname]
      else
        (a, b) -> a[fieldName].localeCompare(b[fieldName])

  _augmentCards: (cards) ->
    for card in cards
      card.subtypes =
        if card.subtype?
          card.subtype.split(' - ')
        else
          []

      switch card.type
        when 'ICE'
          card.subroutinecount = card.text.match(/\[Subroutine\]/g)?.length || 0
        when 'Identity'
          delete card.cost

angular.module('deckBuilder')
  .service 'cardService', ($http, searchService, filterDescriptors) ->
    new CardService($http, searchService, filterDescriptors)
