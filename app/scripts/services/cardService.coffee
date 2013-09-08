'use strict';

class CardService
  CARDS_URL = '/data/cards.json'

  constructor: ($http) ->
    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .then(({ data: @_cards, status, headers }) => @_cards)
      .catch((err) => console.error 'Error loading cards', err)

  cards: ->
    @_cardsPromise

angular.module('deckBuilder')
  .service 'cardService', ($http) ->
    new CardService($http)
