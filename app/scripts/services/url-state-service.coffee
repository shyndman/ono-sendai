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

  constructor: (@$rootScope, @$location, @$log, @filterDescriptors) ->
    @generatedUrl = undefined
    @$rootScope.$on '$locationChangeSuccess', @_locationChanged
    window.test = @test

  test: (path = 'snooky') =>
    @$location.path(path)
    @$rootScope.$digest()

  # Updates the URL to reflect user interaction
  updateUrl: (filterArgs) ->
    url = "/cards/#{ filterArgs.side.toLowerCase() }"

    if filterArgs.activeGroup.name != 'general'
      url += "/#{ filterArgs.activeGroup.name }"

    # TODO We do something really similar in the card service, so maybe we should DRY this up.
    excluded = {}
    relevantFilters = _.extend({}, _(@filterDescriptors)
      .chain()
      .pairs()
      # Remove all groups that are not general or the active group
      .filter(([ name, group ]) -> name == 'general' or name == filterArgs.activeGroup.name)
      .map(([ name, group ]) -> group)
      .tap((groups) ->
        # Determine the excluded fields, used later in this chain
        excluded = _.extend({},
          _(groups)
            .chain()
            .pluck('excludedGeneralFields')
            .compact()
            .value()...))
      # Grab the fields
      .pluck('fieldFilters')
      .compact()
      # Remove
      .map((fieldFilters) =>
        _.filterObj(fieldFilters, (name, desc) =>
          !excluded[name]? and @_isFilterApplicable(desc, filterArgs.fieldFilters[name], filterArgs)))
      .value()...)

    search = {}
    for name, desc of relevantFilters
      switch desc.type
        when 'numeric'
          urlVal = filterArgs.fieldFilters[name].value
          urlOp = DATA_TO_URL_OPERATORS[filterArgs.fieldFilters[name].operator]
          search[name] = "#{ urlOp }:#{ urlVal }"
        when 'inSet'
          search[name] = ''
        when 'search'
          search.search = filterArgs.search

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
  .service('urlStateService', ($rootScope, $location, $log, filterDescriptors) ->
    new UrlStateService(arguments...))
