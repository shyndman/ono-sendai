'use strict';

class UrlStateService
  constructor: ->


angular.module('deckBuilderApp')
  .service 'urlStateService', ($rootScope) ->
    new UrlStateService($rootScope)
