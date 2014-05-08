# The card service is responsible for loading, filtering and grouping cards.
#
# Querying the card service is kicked off by a call to query(), which takes a
# queryArgs object (default defined in filter-definitions.coffee), and performs
# the following steps:
#
#   1. Performs a full-text search using the SearchService, if the user has provided
#      a queryArgs.search value.
#   2. Determines which filters should be applied, based on the active group
#      (queryArgs.activeGroup) and the validity of query arguments, and generates
#      a filter predicate.
#   3. Applies the generated filter predicate against the pool of cards (which may be
#      smaller if a full-text search has been performed).
#   4. Groups/sorts the cards according to the property names defined queryArgs.groupByFields.
#   5. Constructs a QueryResult instance, containing card and group information, as well
#      as lists of objects that are mappable to card IDs (like DOM elements, for instance).
#
# The implementation is deliberately naïve in order to manage complexity. If the card
# pool grows to a size where an O(n) search is no longer viable, I will be revisiting the
# solution.
#
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
    'Shaper':             2
    'Haas-Bioroid':       3
    'Jinteki':            4
    'NBN':                5
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
    @_cards = []
    @_sets = []
    @_setsByTitle = {}
    @_setsById = {}
    @subtypeCounts = corp: {}, runner: {}
    @subtypes = corp: [], runner: []
    @illustratorCounts = corp: {}, runner: {}
    @illustrators = corp: [], runner: []

    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .then(({ data: { sets: @_sets, cards: @_cards, 'last-modified': lastMod }, status, headers }) =>
        # Build up search indexes
        @searchService.indexCards(@_cards, lastMod)

        # Order is important here
        @_initCards(@_cards)
        @_initSets(@_sets)
        @_initSubtypes()
        @_initIllustrators()

        @_cards)

  # Returns a promise that resolves when the card service is ready to be queried.
  ready: ->
    @_cardsPromise

  # Returns a promise that resolves to the cards after they've loaded
  getCards: ->
    @_cardsPromise

  # Returns a promise that resolves to a 2-element array of sets and released sets after they've loaded
  getSets: ->
    @_cardsPromise.then =>
      releasedSets = _.filter @_sets, (set) ->
        set.isReleased()

      [ @_sets, releasedSets ]

  # Consumers should be aware that this will return undefined if the cards have not loaded
  getSetByTitle: (title) ->
    @_setsByTitle[title]

  # Returns an query result object, which describes which cards passed the filter, their positions, and group
  # membership.
  query: (queryArgs = {}) ->
    queryArgs.fieldFilters ?= {}

    @_cardsPromise
      .then((cards) =>
        _.logGroup('Card query', true, _.timed('Query duration', =>
          @$log.debug('Args:', queryArgs)

          filteredCards = @_filterCards(queryArgs, @_searchCards(queryArgs, cards))
          groups = @_groupCards(queryArgs, filteredCards)
          resultSet = @_buildQueryResult(queryArgs, groups)

          @$log.debug("Cards matching query: #{ resultSet.length }")
          resultSet
        )))

  _searchCards: ({ search, byTitle }) =>
    if _.trim(search).length > 0
      @searchService.search(search, byTitle)
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
    activeName = queryArgs.activeGroup
    if !activeName? or activeName is 'general'
      null
    else
      cardType = @filterDescriptors[activeName].cardType
      _.object([ cardType] , [ true ])

  # Returns the set of filter descriptors that are currently relevant to the
  # specified set of arguments.
  #
  # filterNotApplicables - if true, any field filters who do not have the necessary
  #     query arguments to execute will be filtered out of the result.
  relevantFilters: (queryArgs, filterNotApplicables = true) =>
    groups = ['general']
    excludeds = {} # Fields that will not be used to filter

    if queryArgs.activeGroup? and queryArgs.activeGroup isnt 'general'
      groups.push(queryArgs.activeGroup)
      excludeds = @filterDescriptors[queryArgs.activeGroup].excludedGeneralFields ? excludeds

    _(groups)
      .chain()
      # Grab the filter descriptors for each group
      .map((name) => @filterDescriptors[name])
      # Filter out the ones that don't have field filters
      .filter((group) => group.fieldFilters?)
      # Take the field filters
      .pluck('fieldFilters')
      # Map onto objects containing only applicable field filters, as determined by the
      # validity of query arguments, and any exclusions defined by the active group.
      .map((fields) =>
        _.filterObj(fields, (name, desc) =>
          fieldArg = queryArgs.fieldFilters[name]
          return !excludeds[name]? and
                (!filterNotApplicables or @_isFilterApplicable(desc, fieldArg, queryArgs))))
      # Turn the list of objects into a list of kv pair arrays
      .map(_.pairs)
      # Flatten down 1 level, so we're left with an array of [name, value] pairs
      .flatten(true)
      # Objectify
      .object()
      .value()

  # Returns true if the query arguments satisfy a given filter's requirements. For example,
  # numeric filters require a value and a comparison operator to be applicable.
  _isFilterApplicable: (desc, fieldArg, queryArgs) ->
    switch desc.type
      when 'numeric'
        fieldArg? and fieldArg.operator? and fieldArg.value?
      when 'search' # NOTE: Only ever one search field
        queryArgs.search? and !!queryArgs.search.length
      else
        # [todo] This is confusing.
        fieldArg? and (!_.isString(fieldArg) or !!fieldArg.length)

  # Builds and returns a filter predicate, determined by the contents of the provided
  # query args.
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
      when 'match'
        @_buildMatchFilter(filterDesc, filterArg)
      when 'showSpoilers'
        @_buildSpoilerFilter(filterDesc, filterArg)
      when 'search'
        undefined # Search is handled by another stage in the pipeline
      else
        console.warn "Unknown filter type: #{ filterDesc.type }"

  _buildNumericFilter: (filterDesc, filterArg) ->
    cardFields =
      if _.isArray(filterDesc.cardField)
        filterDesc.cardField
      else
        [filterDesc.cardField]

    (card) ->
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
          fieldVal[filterArg]

  # [todo] Support multiple card sets
  _buildCardSetFilter: (filterDesc, filterArg) =>
    set = @_setsById[filterArg]
    (card) ->
      card.setname == set.title

  _buildMatchFilter: (filterDesc, filterArg) =>
    (card) ->
      fieldVal = card[filterDesc.cardField] == filterArg

  _buildSpoilerFilter: (filterDesc, filterArg) =>
    if filterArg
      null
    else
      (card) =>
        @_setsByTitle[card.setname].isReleased()

  _groupCards: ({ groupByFields }, cards) =>
    sortFns =
      _(groupByFields)
        .chain()
        .concat(['title'])
        .map(@_sortFnFor)
        .value()

    _(cards)
      .chain()
      .multiSort(sortFns...)
      # Groups by an array of card values, which is stringified into a comma-separated list to produce the group key.
      #
      # Output example:
      # {
      #   "Jinteki,Identity": [ list of Jinteki identity cards ],
      #   "Jinteki,Asset":    [ list of Jinteki asset cards ],
      #   ...
      # }
      .groupBy((card) -> _.map(groupByFields, (g) -> card[g]))
      .pairs()
      .map((pair) =>
        # Example above becomes 'jinteki identity'
        id: pair[0].replace(/,/g, ' ').toLowerCase()
        # Example above becomes ['Jinteki', 'Identity']
        title: pair[0].split(',')
        cards: pair[1])
      .value()

  _buildQueryResult: (queryArgs, groups) ->
    queryResult = new QueryResult
    _.each(groups, (group) ->
      _.each(group.cards, (c) ->
        queryResult.addCard(c, group)))
    queryResult

  _sortFnFor: (fieldName) =>
    switch fieldName
      when 'type'
        (a, b) => CARD_ORDINALS[a.type] - CARD_ORDINALS[b.type]

      when 'faction'
        (a, b) => FACTION_ORDINALS[a.faction] - FACTION_ORDINALS[b.faction]

      when 'cost', 'factioncost', 'strength', 'trash', 'minimumdecksize', 'influencelimit', 'agendapoints', 'advancementcost'
        (a, b) =>
          _.numericCompare(a[fieldName], b[fieldName])

      when 'setname'
        (a, b) => @_setsByTitle[a.setname].ordinal - @_setsByTitle[b.setname].ordinal

      else # string
        (a, b) =>
          _.stringCompare(a[fieldName], b[fieldName])

  # Collects information about cards, and mutates them to include properties used
  # by the application.
  _initCards: (cards) =>
    _.each cards, (card) =>
      card.id = _.idify(card.title)

      # Parse out subtypes
      card.subtypes =
        if card.subtype?
          card.subtype.split(/\s+-\s+/g)
        else
          []

      # Next we build up a set of subtypes and logical subtypes. Logical subtypes are
      # invisible to the user, but are used by other systems, including search.
      allSubtypes = card.subtypes.slice()

      if card.logicalsubtypes?
        allSubtypes = allSubtypes.concat(card.logicalsubtypes)

      card.subtypesSet = _.object(
        _.map(allSubtypes, _.idify),
        _.times(allSubtypes.length, -> true))

      # Increment the occurrences of each of the card's subtypes
      side = card.side.toLowerCase()
      for st in card.subtypes
        @subtypeCounts[side][st] ?= 0
        @subtypeCounts[side][st]++

      # Increment the occurrences of each of the card's illustrator counts
      if card.illustrator?
        card.illustratorId = _.idify(card.illustrator)
        @illustratorCounts[side][card.illustrator] ?= 0
        @illustratorCounts[side][card.illustrator]++
      else if card.type != 'Identity' # Core identities have no illustrator
        console.warn "#{ card.title } has no illustrator"

      if card.altart? and card.altart.illustrator?
        card.altart.illustratorId = _.idify(card.altart.illustrator)

      switch card.type
        when 'ICE'
          # [todo] Why not just work this out ahead of time?
          card.subroutinecount ?= # If a card already has a subroutine count set, use it instead
            card.text.match(/\[Subroutine\]/g)?.length || 0

  # Collects information about sets, and mutates them to include properties used
  # by the application.
  _initSets: (sets) =>
    _.each sets, (set, i) =>
      _.extend set,
        id: _.idify(set.title)
        ordinal: i
        isReleased: ->
          now = new Date().getTime()
          if @released?
            new Date(@released).getTime() < now
          else
            false

      @_setsByTitle[set.title] = set
      @_setsById[set.id] = set

  _initSubtypes: =>
    @subtypes = @_buildBySide(@subtypeCounts)

  _initIllustrators: =>
    @illustrators = @_buildBySide(@illustratorCounts)

  # Returns an object structured as follows, intended for easy UI consumption:
  #
  # {
  #   corp:   [ {id: String, title: String }, ... ],
  #   runner: [ {id: String, title: String }, ... ],
  # }
  _buildBySide: (countsBySide) ->
    _.object(
      _.map(countsBySide, (counts, side) ->
        objects =
          _(counts)
            .chain()
            .keys()
            .sort()
            .map((i) ->
              id: _.idify(i)
              title: i)
            .value()
        [side, objects]))


# ~-~-~- QUERY RESULT CLASS

# Contains information about how cards should be sorted and which cards are visible.
class QueryResult
  constructor: ->
    @orderedCards = []
    @orderingById = {}
    @groups = {}
    @length = 0
    # Used because groups and cards both exist in the same ordering space, but groups
    # do not contribute to the length of the query result. We use the offset to
    @_ordinalOffset = 0

  # NOTE: cards must be inserted in order
  addCard: (card, group) ->
    @orderedCards.push(card)
    if !@orderingById[group.id]?
      @orderingById[group.id] = @length + @_ordinalOffset
      @groups[group.id] = group
      @_ordinalOffset++

    @orderingById[card.id] = @length + @_ordinalOffset
    @length++

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

  # NOTE the equals sign. This is a helper function, not a method.
  _cardAtOffset = (offset) ->
    (card) ->
      # NOTE, this could be optimized, but isn't likely a big deal
      idx = @orderedCards.indexOf(card) + offset
      @orderedCards[idx]

  cardAfter: _cardAtOffset(1)
  cardBefore: _cardAtOffset(-1)

  # Returns an array of count cards before the specified card, and an array of count
  # afterwards. If there are not enough cards in the result, as many are returned as possible.
  beforeAndAfter: (card, count) ->
    idx = @orderedCards.indexOf(card)
    if idx == -1
      return [ [], [] ]

    before = @orderedCards.slice(Math.max(0, idx - count), idx)
    after =  @orderedCards.slice(start = idx + 1, start + count)
    [ before, after ]


# ~-~-~- ANGULAR REGISTRATION

angular.module('onoSendai')
  # Note that we do not pass the constructor function directly, as it prevents ngMin from
  # properly rewriting the code to be minify-friendly.
  .service('cardService', ($http, $log, searchService, filterDescriptors) ->
    new CardService(arguments...))
