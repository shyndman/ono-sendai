'use strict';

class UrlStateService
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
        _.filterObj(fieldFilters, (key, desc) =>
          !excluded[key]? and @_isFilterApplicable(desc, filterArgs.fieldFilters[key])))
      .value()...)

    @$log.debug(relevantFilters)

    @$location.url url, true
    @generatedUrl = url

  _isFilterApplicable: (desc, args) ->
    switch desc.type
      when 'numeric'
        args.operator? and args.value?
      when 'search'
        # args.
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
