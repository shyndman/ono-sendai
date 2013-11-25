'use strict';

class UrlStateService
  # Mapping of how URLs appear in the data vs how they appear in the URL
  DATA_TO_URL_OPERATORS =
    '=': 'eq'
    '≠': 'neq'
    '<': 'lt'
    '≤': 'lte'
    '>': 'gt'
    '≥': 'gte'

  URL_TO_DATA_OPERATORS = _.invert(DATA_TO_URL_OPERATORS)

  constructor: (@$rootScope, @$location, @$log, @cardService, @filterUI, @filterDefaults) ->
    @generatedUrl = undefined
    @$rootScope.$on '$locationChangeSuccess', @_locationChanged

    generalFields = _.find(@filterUI, (group) -> group.name is 'general').fieldFilters

    # Used to provide pretty faction abbreviations to the URL
    @factionUiMappingsBySide = _.find(generalFields, (field) -> field.name is 'faction').side

    # Build the initial filter from the URL
    [ @queryArgs, @selectedCardId ] = @_stateFromUrl()

  # Updates the URL to reflect the current query arguments
  updateUrl: (queryArgs, selectedCard) ->
    @$log.debug('Updating URL with latest query arguments')

    url = "/cards/#{ queryArgs.side.toLowerCase() }"

    if queryArgs.activeGroup.name != 'general'
      url += "/#{ queryArgs.activeGroup.name }"

    if selectedCard?
      url += "/card/#{ selectedCard.id }"

    # Build up the query string parameters
    search = {}
    for name, desc of @cardService.relevantFilters(queryArgs)
      arg = queryArgs.fieldFilters[name]
      switch desc.type
        when 'numeric'
          urlVal = arg.value
          urlOp = DATA_TO_URL_OPERATORS[arg.operator]
          search[name] = "#{ urlOp }:#{ urlVal }"
        when 'inSet'
          search[name] =
            if name is 'faction'
              relevantFactions = @factionUiMappingsBySide[queryArgs.side.toLowerCase()]
              @_factionSearchVal(relevantFactions, arg)
            else
              if _.isArray(arg)
                arg.join(',')
              else
                arg
        when 'search'
          search.search = queryArgs.search
        else
          search[name] = arg

    # Set the generated URL
    @$location.url(url).search(search)

    # Determine whether we should push the URL, or whether we should replace it.
    pushUrl = (!selectedCard? and  @selectedCardId?) or
              ( selectedCard? and !@selectedCardId?) or
              (@queryArgs.side != queryArgs.side)
    @$location.replace() if !pushUrl

    # Update local state
    @generatedUrl = @$location.url()
    @queryArgs = angular.copy(queryArgs)
    @selectedCardId = selectedCard?.id

  # Returns the search value for
  _factionSearchVal: (factions, arg) ->
    if _.every(factions, (f) -> arg[f.model])
      'all'
    else
      _(factions)
        .chain()
        .filter((f) -> arg[f.model])
        .pluck('abbr')
        .value()
        .join(',')

  _locationChanged: (e, newUrl, oldUrl) =>
    # If this service is responsible for the last URL update, don't react to it
    if @$location.url() == @generatedUrl
      return

    @$log.debug "URL changed to #{ @$location.url() }"
    [ @queryArgs, @selectedCardId ]  = @_stateFromUrl()
    @$rootScope.$broadcast('urlStateChange')

  _cardsUrlMatcher:
    ///
      ^
      /cards
      /(corp|runner)
      (?: # Selected group
        /
        ([^c][^/]+) # the ^c is to prevent a match on /card/ -- a bit messy
      )?
      (?: # Specific card
        /card/
        ([^/]+)
      )?
    ///

  # [todo] This is getting a bit ugly. Consider a refactor
  _stateFromUrl: ->
    cardsMatch = @$location.path().match(@_cardsUrlMatcher)

    # Copy defaults and assign general as the default active group
    queryArgs = angular.copy(@filterDefaults)
    queryArgs.activeGroup = _.findWhere(@filterUI, name: 'general')

    # No URL match. Return default query arguments.
    if !cardsMatch?
      @$log.debug('No matching URL pattern. Assigning query arg defaults')
      return [ queryArgs, undefined ]

    # Side
    side =  cardsMatch[1]
    queryArgs.side = _.capitalize(side)

    # Active group
    if cardsMatch[2]
      queryArgs.activeGroup = _.findWhere(@filterUI, name: cardsMatch[2]) ? queryArgs.activeGroup

    if cardsMatch[3]
      selectedCardId = cardsMatch[3]

    relevantFilters = @cardService.relevantFilters(queryArgs, false)
    search = @$location.search()

    for name, desc of relevantFilters
      if !search[name]?
        continue

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
          if search[name] == 'all'
            break

          if name == 'faction'
            queryFactions = queryArgs.fieldFilters.faction
            factions = @factionUiMappingsBySide[side]

            modelFlags = _.object(
              _.map(
                search[name].split(','),
                (f) -> _.findWhere(factions, abbr: f).model)
            , [])

            _.each queryFactions, (val, key) ->
              queryFactions[key] = key of modelFlags
          else
            queryArgs.fieldFilters[name] = search[name]

        else # switch
          queryArgs.fieldFilters[name] = search[name]

    [ queryArgs, selectedCardId ]


angular
  .module('deckBuilder')
  .service('urlStateService', ($rootScope, $location, $log, cardService, filterUI, filterDefaults) ->
    new UrlStateService(arguments...))
