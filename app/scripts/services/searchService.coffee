# Wraps a client-side search engine library to expose search functionality to the application.
class SearchService
  constructor: (@$q) ->
    filters = [ @_dediacriticFilter ]
    lunr.tokenizer = @_tokenize
    @_index = lunr ->
      @pipeline.before (->), filter for filter in filters
      @ref 'title'
      @field 'title', boost: 10
      @field 'faction', boost: 5
      @field 'type'
      @field 'subtype'
      @field 'text'
    window.search = @_index.search.bind(@_index) # DEBUG

  indexCards: (@cards) =>
    # Store a map of cards by their title, for later mapping
    @_cardsByTitle = _.object(_.zip(_.pluck(cards, 'title'), cards))
    @_index.add(card) for card in @cards

  # Retuns a promise that will resolve to an array of cards matching the provided query.
  search: (query) =>
    cards = @_mapResultsToCards(@_index.search(query))
    @$q.when(cards)

  _mapResultsToCards: (results) =>
    if !results?
      []
    else
      (@_cardsByTitle[result.ref] for result in results)

  # Replacement tokenizer for lunr
  _tokenize: (obj) =>
    if !arguments.length or !obj?
      []
    else if _.isArray(obj)
      obj.map (t) -> t.toLowerCase()
    else
      str = obj.toString().replace(/[\[\]{}'"]/g, ' ')
      words =
        _(str).chain()
              .stripTags()
              .words()
              .value()

  _dediacriticFilter: (token, tokenIndex, tokens) =>
    _.stripDiacritics(token)

# Register the service
angular.module('deckBuilder').service 'searchService', SearchService
