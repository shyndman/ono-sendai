'use strict';

class UrlStateService
  # Mapping of how URLs appear in the data vs how they appear in the URL
  DATA_TO_URL_OPERATORS =
    '=': 'eq'
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
    @generatedQueryArgs = @_queryArgsFromUrl()

  # Updates the URL to reflect the current query arguments
  updateUrl: (queryArgs, selectedCard) ->
    @$log.debug('Updating URL with latest query arguments')

    relevantFilters = @cardService.relevantFilters(queryArgs)
    url = "/cards/#{ queryArgs.side.toLowerCase() }"

    if queryArgs.activeGroup.name != 'general'
      url += "/#{ queryArgs.activeGroup.name }"

    if selectedCard?
      url += "/card/#{ selectedCard.id }"

    search = {}
    for name, desc of relevantFilters
      arg = queryArgs.fieldFilters[name]
      switch desc.type
        when 'numeric'
          urlVal = arg.value
          urlOp = DATA_TO_URL_OPERATORS[arg.operator]
          search[name] = "#{ urlOp }:#{ urlVal }"
        when 'inSet'
          search[name] =
            switch name
              when 'faction'
                relevantFactions = @factionUiMappingsBySide[queryArgs.side.toLowerCase()]
                @_factionSearchVal(relevantFactions, arg)
              else
                @$log.warn("No URL mapping available for #{ name }")
                ''
        when 'search'
          search.search = queryArgs.search

    @$location.url(url).search(search).replace()
    @generatedUrl = @$location.url()

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
    @generatedQueryArgs = @_queryArgsFromUrl()
    @$rootScope.$broadcast('urlFilterChange', @generatedQueryArgs)

  _cardsUrlMatcher:
    ///
      ^
      /cards
      /(corp|runner)
      (?:/([^/]+))?
    ///

  _queryArgsFromUrl: ->
    cardsMatch = @$location.path().match(@_cardsUrlMatcher)

    # Copy defaults and assign general as the default active group
    queryArgs = angular.copy(@filterDefaults)
    queryArgs.activeGroup = _.findWhere(@filterUI, name: 'general')

    if cardsMatch?
      # Side
      side =  cardsMatch[1]
      queryArgs.side = _.capitalize(side)

      # Active group
      if cardsMatch[2]
        queryArgs.activeGroup = _.findWhere(@filterUI, name: cardsMatch[2]) ? queryArgs.activeGroup

      relevantFilters = @cardService.relevantFilters(queryArgs, false)
      search = @$location.search()

      for name, desc of relevantFilters
        continue unless search[name]?

        switch desc.type
          when 'search'
            queryArgs.search = search.search

          when 'numeric'
            [ op, val ] = search[name].split(':')
            if !val? or !op? or !URL_TO_DATA_OPERATORS[op]?
              break

            queryArgs.fieldFilters[name] =
              operator: URL_TO_DATA_OPERATORS[op],
              value: Number(val)

          when 'inSet'
            if search[name] == 'all'
              break

            if name == 'faction'
              flags = search[name].split(',')
              relevantFactions = @factionUiMappingsBySide[side]
              modelFlags = _.object(
                _.map(flags, (f) -> _.findWhere(relevantFactions, abbr: f).model), [])

              queryFactions = queryArgs.fieldFilters.faction
              _.each(queryFactions, (val, key) -> queryFactions[key] = key of modelFlags)
            else
              @$log.warn("No URL mapping available for #{ name }")


    else
      @$log.debug('No matching URL pattern. Assigning query arg defaults')

    queryArgs


angular
  .module('deckBuilder')
  .service('urlStateService', ($rootScope, $location, $log, cardService, filterUI, filterDefaults) ->
    new UrlStateService(arguments...))
