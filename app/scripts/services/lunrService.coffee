class LunrWrapper
  constructor: ->
  createIndex: (indexFn) -> lunr(indexFn)

angular.module('deckBuilder')
  .service 'lunrService', () ->
    new LunrWrapper()
