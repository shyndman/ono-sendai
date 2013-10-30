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

  constructor: (@$rootScope, @$location, @$log, @cardService, @filterUI) ->
    @generatedUrl = undefined
    @$rootScope.$on '$locationChangeSuccess', @_locationChanged

    generalFieldFilters = _.find(@filterUI, (group) -> group.name is 'general').fieldFilters

    # Used to provide pretty faction abbreviations to the URL
    @factionUiMappingsBySide = _.find(generalFieldFilters, (field) -> field.name is 'faction').side
    window.test = @test

  # Updates the URL to reflect the current query arguments
  updateUrl: (queryArgs) ->
    @$log.debug('Updating URL with latest query arguments')

    relevantFilters = @cardService.relevantFilters(queryArgs)
    url = "/cards/#{ queryArgs.side.toLowerCase() }"

    if queryArgs.activeGroup.name != 'general'
      url += "/#{ queryArgs.activeGroup.name }"

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

    @$log.debug "URL changed to #{ @$location.url() }. Parsing into query arguments."


angular
  .module('deckBuilder')
  .service('urlStateService', ($rootScope, $location, $log, cardService, filterUI) ->
    new UrlStateService(arguments...))
