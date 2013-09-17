'use strict';

class CardService
  CARDS_URL = '/data/cards.json'

  constructor: ($http, @lunrService) ->
    @lunrService = lunrService
    @_cards = []

    # Construct the card index
    @_index = @lunrService.createIndex(-> # Scoped to lunr
      @field 'title', boost: 5,
      @field 'text',
      @field 'faction', boost: 10
      @field 'type'
      @ref 'title'
      @pipeline.add(lunrService.dediacticify))
    window.index = @

    console.log 'creating card service'
    # Begin loading immediately
    @_cardsPromise = $http.get(CARDS_URL)
      .success((@_cards, status, headers) =>
        @_indexCards(@_cards)
        @onCards?(@_cards))
      .catch((err) => console.error 'Error loading cards', err)

  filter: (filter_obj) ->
    @_cardsPromise.then(_.partial(@_applyFilter, filter_obj))

  search: (query) ->
    for { ref } in @_index.search(query)
      @_cardsByTitle[ref]

  _indexCards: (cards) =>
    @_titleize(cards)
    @_cardsByTitle = _.object(_.zip(_.pluck(cards, 'title'), cards))
    for card in cards
      @_index.add(card)
    return

  _titleize: (cards) ->
    _.each(cards, (card) ->
      card.title = _.last(card.title.split('/')))

  cards: (callback) ->
    if !_.isEmpty(@_cards)
      callback @_cards
    else
      @onCards = callback

angular.module('deckBuilder')
  .service 'cardService', ($http, lunrService) ->
    new CardService($http, lunrService)
