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
    'Core Set': 0
    'What Lies Ahead':      1
    'Trace Amount':         2
    'Cyber Exodus':         3
    'A Study in Static':    4
    "Humanity's Shadow":    5
    'Future Proof':         6
    'Creation and Control': 7
    'Opening Moves':        8
    'Second Thoughts':      9
    'Mala Tempora':        10
    'True Colors':         11
    'Fear and Loathing':   12
    'Double Time':         13

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
    selGroup = filterArgs.activeGroup
    if selGroup?
      filterGroups = [] if @filterDescriptors[selGroup.name].excludeGeneral
      filterGroups.push(filterArgs.activeGroup.name)

    filters = _.flatten(
      for groupName in filterGroups
        groupDesc = @filterDescriptors[groupName]
        continue if not groupDesc.fieldFilters?

        for fieldName, fieldDesc of groupDesc.fieldFilters
          filterArg = filterArgs.fieldFilters[fieldName]
          switch fieldDesc.type
            when 'numeric'
              if not filterArg.value? or not filterArg.operator?
                continue
              @_buildNumericFilter(fieldDesc, filterArg) # loop tail
            when 'inSet'
              @_buildInSetFilter(fieldDesc, filterArg)
            else
              console.warn "Unknown filter type: #{ fieldDesc.type }"
              continue)

    if _.isEmpty(filters)
      null
    else
      _.partial(OPERATORS.and, filters)

  # TODO document
  _buildNumericFilter: (filterDescriptor, filterArgs) ->
    (card) ->
      cardFields =
        if _.isArray(filterDescriptor.cardField)
          filterDescriptor.cardField
        else
          [filterDescriptor.cardField]

      for field in cardFields when card[field]?
        fieldVal = card[field]
        return OPERATORS[filterArgs.operator](fieldVal, filterArgs.value)

      false

  # TODO document
  _buildInSetFilter: (filterDescriptor, filterArgs) ->
    (card) ->
      # XXX Special case, to avoid ambiguity between the two Neutral factions (Runner/Corp).
      #     This could probably be accomplished differently, but quick and dirty for now.
      fieldVal =
        if filterDescriptor.cardField is 'faction'
          "#{ card.side }: #{ card.faction }"
        else
          card[filterDescriptor.cardField]

      # Now that we have the card value, we have to map it to the boolean field in the filter
      # argument.
      filterArgs[filterDescriptor.modelMappings[fieldVal]]

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
        title: pair[0]
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
