class DeckService

  constructor: ->

  decks: ->

angular.module('onoSendaiApp')
  .service 'deckService', () ->
    new DeckService(arguments...)
