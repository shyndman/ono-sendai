'use strict';

class CardService
  CARDS_URL = '/data/cards.json'

  constructor: ($http, @lunrService) ->
    @_cards = []

    # Construct the card index
    window.index = @_index = @lunrService.createIndex(-> # Scoped to lunr
      @field 'title', boost: 5,
      @field 'text',
      @field 'faction', boost: 10
      @ref 'title')

    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .then(({ data: @_cards, status, headers }) =>
        @_indexCards(@_cards)
        @_cards)
      .catch((err) => console.error 'Error loading cards', err)

  _indexCards: (cards) =>
    @_titleize(cards)
    @_cardsByTitle = _.object(_.zip(_.pluck(cards, 'title', cards)))
    for card in cards
      @_index.add(card)
    return

  _titleize: (cards) ->
    _.each(cards, (card) ->
      card.title = _.last(card.title.split('/')))

  cards: -> @_cardsPromise

angular.module('deckBuilder')
  .service 'cardService', ($http, lunrService) ->
    new CardService($http, lunrService)
