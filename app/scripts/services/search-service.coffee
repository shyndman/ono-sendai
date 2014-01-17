# Wraps a client-side search engine library to expose card search functionality to the application.
class SearchService
  constructor: (@$q) ->
    filters = [ { lbl: 'stripDiacritics', fn: _.stripDiacritics } ]

    for { lbl, fn } in filters
      lunr.Pipeline.registerFunction fn, lbl

    lunr.tokenizer = @_tokenize
    @_fullIndex = lunr ->
      @pipeline.before (->), fn for { fn } in filters
      @ref 'title'
      @field 'title', boost: 10
      @field 'type'
      @field 'subtype'
      @field 'text'
      @field 'setname'

    @_titleIndex = lunr ->
      @pipeline.before (->), fn for { fn } in filters
      @ref 'title'
      @field 'title'

  indexCards: (@cards, lastMod) =>
    # Store a map of cards by their title, for later mapping
    @_cardsByTitle = _.object(_.zip(_.pluck(cards, 'title'), cards))

    _.time 'Indexing cards', =>
      @_tryCachedIndexes(_.partial(@_indexCards, cards), lastMod)

  # Retuns a promise that will resolve to an array of cards matching the provided query.
  search: (query, byTitle = false) =>
    index = if byTitle then @_titleIndex else @_fullIndex
    @_mapResultsToCards(index.search(query))

  _mapResultsToCards: (results) =>
    if !results?
      []
    else
      (@_cardsByTitle[result.ref] for result in results)

  # Attempts to load a version of the card indexes with the given last modified timestamp. If none
  # is found, the indexes are computed using indexFn, and cached for future use.
  _tryCachedIndexes: (indexFn, lastMod) ->
    cachedIndexes = JSON.parse(localStorage.getItem('searchIndexes'))

    # If we have the right index cached, load it in
    if cachedIndexes? and cachedIndexes[lastMod]?
      for name, data of cachedIndexes[lastMod]
        @[name] = lunr.Index.load(data)
      return

    # Otherwise index the cards
    indexFn()

    # Write the indexes to local storage
    jsonIndexes = {}
    jsonIndexes[lastMod] = _titleIndex: @_titleIndex.toJSON(), _fullIndex: @_fullIndex.toJSON()
    localStorage.setItem('searchIndexes', JSON.stringify(jsonIndexes))

  _indexCards: (cards) =>
    for index in [ @_titleIndex, @_fullIndex ]
      for card in @cards
        index.add(card)

      # Remove the stop word filter, so that we can do prefix matching properly
      index.pipeline.remove(lunr.stopWordFilter)

  # Replacement tokenizer for lunr
  _tokenize: (obj) =>
    if !arguments.length or !obj?
      []
    else if _.isArray(obj)
      obj.map (t) -> t.toLowerCase()
    else
      _(obj.toString())
        .chain()
        .replace(/[\[\]{}'"]/g, ' ')
        .stripTags()
        .words()
        .map((word) -> word.split('-'))
        .flatten()
        .map((word) ->
          word.replace(/[^\w\d\s]+$/, ' ').replace(/^[^\w\d\s]+/, ' ').trim())
        .value()

# Register the service
angular.module('onoSendai')
  .service 'searchService', ($q) ->
    new SearchService($q)
