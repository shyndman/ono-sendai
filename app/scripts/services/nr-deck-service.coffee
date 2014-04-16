# Deck CRUD
class DeckService

  DECK_PREFIX = 'deck-'

  constructor: (@_localStorage) ->
    @_decks = []
    @_deckIds = {}
    @_loadLocalDecks()

  _loadLocalDecks: ->
    for deckId in @_localStorage.getItem('deckIds') ? []
      @_deckIds[deckId] = true
      @_decks.push @_localStorage.getItem(deckId)

  getDecks: ->
    @_decks.splice(0)

  saveDeck: (deck) ->
    if !deck.id
      deck.id = DECK_PREFIX + _.idify(deck.title)

      if @_deckIds[deck.id]
        throw 'Deck ID not unique'

      @_deckIds[deck.id] = true
      @_localStorage.setItem('deckIds', _.keys(@_deckIds))
      @_decks.push deck

    @_localStorage.setItem(deck.id, deck)

  deleteDeck: (deck) ->
    delete @_deckIds[deck.id]
    @_localStorage.setItem('deckIds', _.keys(@_deckIds))
    @_localStorage.deleteItem(deck.id)


angular.module('onoSendai')
  .service('deckService', (localStorage) ->
    new DeckService(arguments...))
