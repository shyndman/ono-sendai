# Contains information about how cards should be sorted and which cards are visible.
class QueryResult
  constructor: ->
    @ordering = {}
    @groups = {}
    @length = 0
    @_ordinalOffset = 0

  # NOTE: cards must be inserted in order
  addCard: (card, group, ordinal) ->
    @length++
    if !@ordering[group.id]?
      @ordering[group.id] = ordinal + @_ordinalOffset
      @groups[group.id] = group
      @_ordinalOffset++

    @ordering[card.id] = ordinal + @_ordinalOffset

  isShown: (id) ->
    @ordering[id]?

  # Applies the query result's ordering to a collection of objects. idFn is applied
  # to each element in order to map the element to card identifiers.
  #
  # Elements that do not appear in the query results are placed at the end of the collection.
  applyOrdering: (collection, idFn) ->
    _.sortBy collection, (ele) =>
      @ordering[idFn(ele)] ? Number.MAX_VALUE

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

  # TODO It would be nice if this could be part of cards.json
  SET_ORDINALS =
    'Core Set':              0
    'What Lies Ahead':       1 # Dec '12
    'Trace Amount':          2 # Jan '13
    'Cyber Exodus':          3 # Feb '13
    'A Study in Static':     4 # Mar '13
    "Humanity's Shadow":     5 # May '13
    'Future Proof':          6 # Jun '13
    'Creation and Control':  7 # Jul '13
    'Opening Moves':         8 # Sep '13
    'Second Thoughts':       9 # Nov '13
    'Mala Tempora':         10 # Dec '13
    'True Colors':          11 # Jan '14
    'Fear and Loathing':    12 # Feb '14
    'Double Time':          13 # ?

  OPERATORS =
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

  subTypes:
    corp: {}
    runner: {}

  comparisonOperators: ['=', '<', '≤', '>', '≥']

  constructor: ($http, @$log, @searchService, @filterDescriptors) ->
    @searchService = searchService
    @_cards = []

    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .then(({ data: @_cards, status, headers }) =>
        window.cards = @_cards # DEBUG
        @searchService.indexCards(@_cards)
        @_augmentCards(@_cards)
        @_cards)

  getCards: -> @_cardsPromise

  # Returns an filter result object, which describes which cards passed the filter, their positions, and group
  # membership.
  query: (queryArgs = {}) ->

    # Each step in the card filtering pipeline can choose to be asynchronous if needed
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
    return (if queryArgs.side?  then card.side is queryArgs.side  else true) and # TODO This should be extracted into filter functions
           (if enabledTypes?    then enabledTypes[card.type]      else true) and
           (if filterFn?        then filterFn(card)               else true)

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

  _buildFilterFunction: (queryArgs, enabledTypes) =>
    filterGroups = ['general']
    filterGroups.push queryArgs.activeGroup.name if queryArgs.activeGroup
    excludeFields = queryArgs.activeGroup?.excludedGeneralFields? || {}

    filters = _(filterGroups)
      .chain()
      .map((name) => @filterDescriptors[name])
      .filter((group) => group.fieldFilters?)
      .pluck('fieldFilters')
      .map((fields) =>
        _.map(fields, (field, name) =>
          if !excludeFields[name]? and (!field.inclusionPredicate? or field.inclusionPredicate(queryArgs))
            @_buildFilter(field, queryArgs.fieldFilters[name])))
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
      when 'search'
        undefined # Search is handled by another stage in the pipeline
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
        id: pair[0].replace(/,/g, ' ').toLowerCase()
        type: 'group'
        title: pair[0].split(',')
        cards: pair[1])
      .value()

  _buildQueryResult: (queryArgs, groups) ->
    ordinal = 0
    queryResult = new QueryResult
    _(groups).each((group) ->
      _.each(group.cards, (c) ->
        queryResult.addCard(c, group, ordinal++)))
    queryResult

  _sortFnFor: (fieldName) =>
    switch fieldName
      when 'type'
        (a, b) -> CARD_ORDINALS[a.type] - CARD_ORDINALS[b.type]
      when 'faction'
        (a, b) -> FACTION_ORDINALS[a.faction] - FACTION_ORDINALS[b.faction]
      when 'cost', 'factioncost'
        (a, b) ->
          if a[fieldName] is undefined or b[fieldName] is undefined
            0 # Allow the next sort to take precedence
          else
            a[fieldName] - b[fieldName]
      when 'setname'
        (a, b) -> SET_ORDINALS[a.setname] - SET_ORDINALS[b.setname]
      else
        (a, b) -> a[fieldName].localeCompare(b[fieldName])

  _augmentCards: (cards) =>
    for card in cards
      card.subtypes =
        if card.subtype?
          card.subtype.split(' - ')
        else
          []

      # Does the trick for now
      card.id = card.imagesrc

      # Increment the occurrences of each of the card's subtypes
      side = card.side.toLowerCase()
      for st in card.subtypes
        if @subTypes[side][st]?
          @subTypes[side][st]++
        else
          @subTypes[side][st] = 1

      switch card.type
        when 'ICE'
          card.subroutinecount = card.text.match(/\[Subroutine\]/g)?.length || 0
        when 'Identity'
          delete card.cost # It's unclear why the raw data has this field on identities -- it shouldn't

angular.module('deckBuilder')
  # Note that we do not pass the constructor function directly, as it prevents ngMin from
  # properly rewriting the code to be minify-friendly.
  .service('cardService', ($http, $log, searchService, filterDescriptors) ->
    new CardService(arguments...))
