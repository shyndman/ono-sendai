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

  constructor: (@$rootScope, @$location, @$log, @cardService) ->
    @generatedUrl = undefined
    @$rootScope.$on '$locationChangeSuccess', @_locationChanged
    window.test = @test

  # Updates the URL to reflect the current query arguments
  updateUrl: (queryArgs) ->
    relevantFilters = @cardService.relevantFilters(queryArgs)
    url = "/cards/#{ queryArgs.side.toLowerCase() }"

    if queryArgs.activeGroup.name != 'general'
      url += "/#{ queryArgs.activeGroup.name }"

    search = {}
    for name, desc of relevantFilters
      switch desc.type
        when 'numeric'
          urlVal = queryArgs.fieldFilters[name].value
          urlOp = DATA_TO_URL_OPERATORS[queryArgs.fieldFilters[name].operator]
          search[name] = "#{ urlOp }:#{ urlVal }"
        when 'inSet'
          search[name] = ''
        when 'search'
          search.search = queryArgs.search

    @$location.url(url).search(search).replace()
    @generatedUrl = @$location.url()

  _isFilterApplicable: (desc, fieldArgs, allArgs) ->
    switch desc.type
      when 'numeric'
        fieldArgs.operator? and fieldArgs.value?
      when 'search' # NOTE: Only ever one search field
        allArgs.search? and !!allArgs.search.length
      else
        true

  _locationChanged: (e, newUrl, oldUrl) =>
    # If this service is responsible for the last URL update, don't react to it
    if @$location.url() == @generatedUrl
      return

    @$log.debug "URL changed to #{ @$location.url() }"

angular
  .module('deckBuilder')
  .service('urlStateService', ($rootScope, $location, $log, cardService) ->
    new UrlStateService(arguments...))
