# Transforms a URL into a queryArgs object, and vice-versa. That's it!
class UrlStateService
  # Mapping of how operators appear in the data vs how they appear in the URL
  DATA_TO_URL_OPERATORS =
    '=': 'eq'
    '≠': 'neq'
    '<': 'lt'
    '≤': 'lte'
    '>': 'gt'
    '≥': 'gte'

  URL_TO_DATA_OPERATORS = _.invert(DATA_TO_URL_OPERATORS)

  DECKS_URL_MATCHER =
    ///
      ^
      /decks
      (?:
        /([^/]*) # 1 - new or deck ID
        (?:/edit
          (.*)   # 2 - card filters - passed along to cards URL matcher
        )?
      )?
    ///

  CARD_URL_MATCHER =
    ///
      ^
      /cards
      (?:
        /(corp|runner) # 1 - side
      )?
      (?:
        /
        ([^c][^/]+)    # 2 - card type -- [note] the ^c is to prevent a match on /card/ (kind of gross)
      )?
      (?:
        /card/
        ([^/]+)        # 3 - card
        (?:
          /([^/])      # 4 - card page
        )?
      )?
    ///

  constructor: (@$rootScope, @$location, @$log, @cardService, @filterUI, @queryArgDefaults) ->
    @generatedUrl = undefined
    @$rootScope.$on '$locationChangeSuccess', @_locationChanged

    generalFields = _.find(@filterUI, (group) -> group.name is 'general').fieldFilters

    # Used to provide pretty faction abbreviations to the URL
    @factionUiMappingsBySide = _.find(generalFields, (field) -> field.name is 'faction').sideFactions

    # Build the initial filter from the URL
    @_setStateFromUrl()

  # Invoked when the location changes to update the query arguments
  _locationChanged: (e, newUrl, oldUrl) =>
    # If this service is responsible for the last URL update, don't react to it
    if @$location.url() == @generatedUrl
      return

    @$log.debug "URL changed to #{ @$location.url() }"
    @_setStateFromUrl()
    @$rootScope.$broadcast('urlStateChange')

  # Updates the URL to reflect the current query arguments
  updateUrl: (queryArgs = @queryArgs, selectedCard, cardPage, forcePushState = false) ->
    @$log.debug('Updating URL with latest query arguments')

    url = '/cards'
    search = {}

    if queryArgs.side?
      url += "/#{ queryArgs.side.toLowerCase() }"

    if queryArgs.activeGroup != 'general'
      group = _.findWhere(@filterUI, name: queryArgs.activeGroup)
      url += "/#{ group.display }"

    if selectedCard?
      url += "/card/#{ selectedCard.id }"

    if cardPage? and cardPage == 'cost-to-break'
      url += "/$"

    # Build up the query string parameters
    for name, desc of @cardService.relevantFilters(queryArgs)
      arg = queryArgs.fieldFilters[name]
      searchVal = @_filterSearchVal(queryArgs, name, desc, arg)

      if !searchVal?
        continue
      else if _.isArray(searchVal)
        search[searchVal[0]] = searchVal[1]
      else
        search[name] = searchVal

    # Grouping (if not default)
    if !angular.equals(queryArgs.groupByFields, [ 'faction', 'type' ])
      search.group = queryArgs.groupByFields.join(',')

    # Determine whether we should push the URL, or whether we should replace it.
    pushUrl = forcePushState or
              (!selectedCard? and  @selectedCardId?) or
              ( selectedCard? and !@selectedCardId?) or
              (@queryArgs.side != queryArgs.side)

    # Set the generated URL
    @$location.url(url).search(search)
    @$location.replace() if !pushUrl

    # Update local state
    @generatedUrl = @$location.url()
    @queryArgs = angular.copy(queryArgs)
    @selectedCardId = selectedCard?.id

  # Returns the query string variable value for the filter with the
  # specified name, description and argument. If this method returns
  # a two-element array,
  _filterSearchVal: (queryArgs, name, desc, arg) =>
    switch desc.type
      when 'numeric'
        urlVal = arg.value
        urlOp = DATA_TO_URL_OPERATORS[arg.operator]
        "#{ urlOp }:#{ urlVal }"

      when 'inSet'
        if name is 'faction'
          if queryArgs.side?
            relevantFactions = @factionUiMappingsBySide[queryArgs.side.toLowerCase()]
            @_factionSearchVal(relevantFactions, arg)
          else
            null
        else
          if _.isArray(arg)
            arg.join(',')
          else
            arg

      when 'search'
        [ 'search', queryArgs.search ]

      when 'showSpoilers'
        # noop

      else
        arg

  # Returns a comma separated string of faction abbreviations, based on the factions
  # provided.
  _factionSearchVal: (factions, arg) ->
    if !_.every(factions, (f) -> arg[f.model])
      _(factions)
        .chain()
        .filter((f) -> arg[f.model])
        .pluck('abbr')
        .value()
        .join(',')

  _setStateFromUrl: =>
    [ @queryArgs, @selectedCardId, @cardPage ] = @_stateFromUrl()

  _stateFromUrl: ->
    selectedCardId = null
    cardPage = null
    queryArgs = angular.copy(@queryArgDefaults.get())
    search = @$location.search()
    cardsMatch = @$location.path().match(CARD_URL_MATCHER)

    # No URL match. Return default query arguments.
    if !cardsMatch?
      @$log.debug('No matching URL pattern. Assigning query arg defaults')
      return [ queryArgs, undefined, undefined ]

    if (side = cardsMatch[1])?
      queryArgs.side = _.capitalize(cardsMatch[1])

    if cardsMatch[2]
      queryArgs.activeGroup = _.findWhere(@filterUI, display: cardsMatch[2])?.name ? queryArgs.activeGroup

    if cardsMatch[3]
      selectedCardId = cardsMatch[3]

    if cardsMatch[4]
      switch cardsMatch[4].trim()
        when '$'
          cardPage = 'cost-to-break'
        else
          @$log.warn("Unrecognized card page #{ cardsMatch[4] }")

    for name, desc of @cardService.relevantFilters(queryArgs, false) when search[name]?
      @_setQueryValFromSearch(queryArgs, search, name, desc, side)

    # Groupings
    if search.group
      queryArgs.groupByFields = search.group.split(',')

    [ queryArgs, selectedCardId, cardPage ]

  # Populates the supplied queryArgs with a single argument, as described
  # by name and desc.
  _setQueryValFromSearch: (queryArgs, search, name, desc, side) =>
    switch desc.type
      when 'search'
        queryArgs.search = search.search

      when 'numeric'
        [ op, val ] = search[name].split(':')
        if !val? or !op? or !URL_TO_DATA_OPERATORS[op]?
          break

        queryArgs.fieldFilters[name] =
          operator: URL_TO_DATA_OPERATORS[op]
          value: Number(val)

      when 'inSet'
        if name == 'faction'
          queryFactions = queryArgs.fieldFilters.faction
          factions = @factionUiMappingsBySide[side]

          modelFlags = _(search[name].split(','))
            .chain()
            .map((f) -> _.findWhere(factions, abbr: f)?.model)
            .compact()
            .object([])
            .value()

          _.each queryFactions, (val, key) ->
            queryFactions[key] = key of modelFlags
        else
          queryArgs.fieldFilters[name] = search[name]

      else
        queryArgs.fieldFilters[name] = search[name]


angular
  .module('onoSendai')
  .service('urlStateService', ($rootScope, $location, $log, cardService, filterUI, queryArgDefaults) ->
    new UrlStateService(arguments...))
  # Google Analytics
  .run(($rootScope, $location) ->
    $rootScope.$on('$locationChangeSuccess', ->
      ga('send', 'pageview', page: $location.url())))
