# Contains information about how cards should be sorted and which cards are visible.
class QueryResult
  constructor: ->
    @orderedCards = []
    @orderingById = {}
    @groups = {}
    @length = 0
    @_ordinalOffset = 0

  # NOTE: cards must be inserted in order
  addCard: (card, group, ordinal) ->
    @orderedCards.push(card)
    @length++
    if !@orderingById[group.id]?
      @orderingById[group.id] = ordinal + @_ordinalOffset
      @groups[group.id] = group
      @_ordinalOffset++

    @orderingById[card.id] = ordinal + @_ordinalOffset

  isShown: (id) ->
    @orderingById[id]?

  # Applies the query result's ordering to a collection of objects. idFn is applied
  # to each element in order to map the element to card identifiers.
  #
  # Elements that do not appear in the query results are placed at the end of the collection.
  applyOrdering: (collection, idFn) ->
    _.sortBy collection, (ele) =>
      @orderingById[idFn(ele)] ? Number.MAX_VALUE

  cardOrdinal: (card) ->
    @orderedCards.indexOf(card)

  # NOTE the equals. This is not a method.
  _cardAtOffset = (offset) ->
    (card) ->
      # NOTE, this could be optimized, but isn't likely a big deal
      idx = @orderedCards.indexOf(card) + offset
      @orderedCards[idx]

  cardAfter: _cardAtOffset(1)
  cardBefore: _cardAtOffset(-1)


# A service for loading, filtering and grouping cards.
class CardService
  CARDS_URL = '/data/cards.json'

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

  FACTION_ORDINALS =
    'Anarch':             0
    'Criminal':           1
    'Haas-Bioroid':       2
    'Jinteki':            3
    'NBN':                4
    'Shaper':             5
    'Weyland Consortium': 6
    'Neutral':            7

  OPERATORS =
    'and': (predicates, args...) ->
      for p in predicates
        if not p(args...)
          return false
      true
    '=': (a, b) -> a == b
    '≠': (a, b) -> a != b
    '<': (a, b) -> a < b
    '≤': (a, b) -> a <= b
    '>': (a, b) -> a > b
    '≥': (a, b) -> a >= b

  comparisonOperators: [
    { display: '=', typed: '==' },
    { display: '≠', typed: '!=' },
    { display: '<', typed: '<' },
    { display: '≤', typed: '<=' },
    { display: '>', typed: '>' },
    { display: '≥', typed: '>=' }
  ]

  constructor: ($http, @$log, @searchService, @filterDescriptors) ->
    @searchService = searchService
    @_cards = []
    @_sets = []
    @_setsByTitle = {}
    @_setsById = {}
    @subtypeCounts = corp: {}, runner: {}
    @subtypes = corp: [], runner: []

    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .then(({ data: { sets: @_sets, cards: @_cards }, status, headers }) =>
        window.cards = @_cards # DEBUG
        @searchService.indexCards(@_cards)
        @_augmentCards(@_cards)
        @_augmentSets(@_sets)
        @_initSubtypes()
        @_cards)

  # Returns a promise that resolves when the card service is ready
  ready: ->
    @_cardsPromise

  # Returns a promise that resolves to the cards after they've loaded
  getCards: ->
    @_cardsPromise

  # Returns a promise that resolves to the sets after they've loaded
  getSets: ->
    @_cardsPromise.then => @_sets

  # Consumers should be aware that this will return undefined if the cards have not loaded
  getSetByTitle: (title) ->
    @_setsByTitle[title]

  # Returns an filter result object, which describes which cards passed the filter, their positions, and group
  # membership.
  query: (queryArgs = {}) ->
    @_cardsPromise
      .then((cards) =>
        _.logGroup('Card query', _.timed('Query duration', =>
          @$log.debug('Args:', queryArgs)

          filteredCards = @_filterCards(queryArgs, @_searchCards(queryArgs, cards))
          groups = @_groupCards(queryArgs, filteredCards)
          resultSet = @_buildQueryResult(queryArgs, groups)

          @$log.debug("Cards matching query: #{ resultSet.length }")
          resultSet
        )))

  _searchCards: ({ search }) =>
    if _.trim(search).length > 0
      @searchService.search(search)
    else
      @_cards

  _filterCards: (queryArgs, cards) =>
    enabledTypes = @_enabledTypes(queryArgs)
    filterFn = @_buildFilterFunction(queryArgs, enabledTypes)
    card for card in cards when @_matchesFilter(card, queryArgs, { enabledTypes, filterFn })

  # Returns true if the provided card passes the filters.
  _matchesFilter: (card, queryArgs, { enabledTypes, filterFn }) =>
    return (if queryArgs.side?  then card.side is queryArgs.side else true) and # [todo] This should be extracted into filter functions
           (if enabledTypes?    then enabledTypes[card.type]     else true) and # [todo] So should this
           (if filterFn?        then filterFn(card)              else true)

  # Returns a map of card type names (as they appear in cards.json) to boolean values, indicating whether
  # they should be returned (true) or not (undefined).
  #
  # If null is returned, all cards should be shown.
  _enabledTypes: (queryArgs) =>
    activeName = queryArgs.activeGroup?.name
    if !activeName? or activeName is 'general'
      null
    else
      cardType = @filterDescriptors[activeName].cardType
      enabledTypes = {}
      enabledTypes[cardType] = true
      enabledTypes

  # Returns the set of filter descriptors that are currently relevant to the
  # specified set of arguments.
  #
  # filterNotApplicables - if true, any field filters who do not have the necessary
  #     query arguments to execute will be filtered out of the result.
  relevantFilters: (queryArgs, filterNotApplicables = true) =>
    groups = ['general']
    excludeds = {} # Fields that will not be used to filter

    if queryArgs.activeGroup? and queryArgs.activeGroup.name isnt 'general'
      groups.push(queryArgs.activeGroup.name)
      excludeds = @filterDescriptors[queryArgs.activeGroup.name].excludedGeneralFields || {}

    _(groups)
      .chain()
      .map((name) => @filterDescriptors[name])
      .filter((group) => group.fieldFilters?)
      .pluck('fieldFilters')
      .map((fields) =>
        _.filterObj(fields, (name, desc) =>
          fieldArg = queryArgs.fieldFilters[name]
          return !excludeds[name]? and
                (!filterNotApplicables or @_isFilterApplicable(desc, fieldArg, queryArgs))))
      .map(_.pairs)
      .flatten(true) # Flatten down 1 level, so we're left with an array of [name, value] pairs
      .object()      # Objectify
      .value()

  _isFilterApplicable: (desc, fieldArg, queryArgs) ->
    switch desc.type
      when 'numeric'
        fieldArg.operator? and fieldArg.value?
      when 'search' # NOTE: Only ever one search field
        queryArgs.search? and !!queryArgs.search.length
      else
        fieldArg?

  _buildFilterFunction: (queryArgs) =>
    relevantFilters = @relevantFilters(queryArgs)

    if !_.isEmpty(relevantFilters)
      filterFns = _(relevantFilters)
        .chain()
        .map((desc, name) => @_buildFilter(desc, queryArgs.fieldFilters[name]))
        .compact()
        .value()
      _.partial(OPERATORS.and, filterFns)

  # NOTE: Validation has already been applied to the filters before this point (by _isFilterApplicable)
  _buildFilter: (filterDesc, filterArg) ->
    switch filterDesc.type
      when 'numeric'
        @_buildNumericFilter(filterDesc, filterArg)
      when 'inSet'
        @_buildInSetFilter(filterDesc, filterArg)
      when 'cardSet'
        @_buildCardSetFilter(filterDesc, filterArg)
      when 'search'
        undefined # Search is handled by another stage in the pipeline
      else
        console.warn "Unknown filter type: #{ filterDesc.type }"

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

  _buildInSetFilter: (filterDesc, filterArg) ->
    (card) ->
      fieldVal =
        # XXX Special case, to avoid ambiguity between the two Neutral factions (Runner/Corp).
        #     This could probably be accomplished differently, but quick and dirty for now.
        if filterDesc.cardField is 'faction'
          "#{ card.side }: #{ card.faction }"
        else
          card[filterDesc.cardField]

      switch filterDesc.subtype
        when 'boolSet'
          filterArg[fieldVal]
        else
          filterArg of fieldVal

  # [todo] Support multiple card sets
  _buildCardSetFilter: (filterDesc, filterArg) =>
    set = @_setsById[filterArg]
    (card) ->
      card.setname == set.title

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
        id: pair[0].replace(/,/g, ' ').toLowerCase()
        type: 'group'
        title: pair[0].split(',')
        cards: pair[1])
      .value()

  _buildQueryResult: (queryArgs, groups) ->
    ordinal = 0
    queryResult = new QueryResult
    _.each(groups, (group) ->
      _.each(group.cards, (c) ->
        queryResult.addCard(c, group, ordinal++)))
    queryResult

  _sortFnFor: (fieldName) =>
    switch fieldName
      when 'type'
        (a, b) => CARD_ORDINALS[a.type] - CARD_ORDINALS[b.type]
      when 'faction'
        (a, b) => FACTION_ORDINALS[a.faction] - FACTION_ORDINALS[b.faction]
      when 'cost', 'factioncost'
        (a, b) =>
          if a[fieldName] is undefined or b[fieldName] is undefined
            0 # Allow the next sort to take precedence
          else
            a[fieldName] - b[fieldName]
      when 'setname'
        (a, b) => @_setsByTitle[a.setname].ordinal - @_setsByTitle[b.setname].ordinal
      else
        (a, b) => a[fieldName].localeCompare(b[fieldName])

  _augmentCards: (cards) =>
    _.each cards, (card) =>
      # Does the trick for now
      card.id = _.idify(card.title)

      # Parse out subtypes
      card.subtypes =
        if card.subtype?
          # [todo] Consider scrubbing cards.json instead of handling multiple dash styles
          card.subtype.split(/\s+[-\u2013\ufe58]\s+/g) # [hyphen,en-dash,em-dash]
        else
          []
      card.subtypesSet = _.object(_.map(card.subtypes, _.idify), [])

      # Increment the occurrences of each of the card's subtypes
      side = card.side.toLowerCase()
      for st in card.subtypes
        @subtypeCounts[side][st] ?= 0
        @subtypeCounts[side][st]++

      switch card.type
        when 'ICE'
          # [todo] This isn't perfect, because it doesn't consider advanceables.
          card.subroutinecount = card.text.match(/\[Subroutine\]/g)?.length || 0
        when 'Identity'
          # It's unclear why the raw data has this field on identities -- it shouldn't. If it does
          # it screws up grouping/sorting
          # [todo] Consider whitelisting fields for specific types in cards.json
          delete card.cost

  _augmentSets: (sets) =>
    _.each sets, (set, i) =>
      set.id = _.idify(set.title)
      set.ordinal = i
      @_setsByTitle[set.title] = set
      @_setsById[set.id] = set

  _initSubtypes: =>
    @subtypes = _.object(
      _.map(@subtypeCounts, (counts, side) ->
        subtypes =
          _(counts)
            .chain()
            .keys()
            .sort()
            .map((st) ->
              id: _.idify(st)
              title: st)
            .value()
        [side, subtypes]))

angular.module('deckBuilder')
  # Note that we do not pass the constructor function directly, as it prevents ngMin from
  # properly rewriting the code to be minify-friendly.
  .service('cardService', ($http, $log, searchService, filterDescriptors) ->
    new CardService(arguments...))
