class DeckService

  constructor: ->

  decks: ->

angular.module('onoSendai')
  .service 'deckService', () ->
    new DeckService(arguments...)
