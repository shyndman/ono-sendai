# Wraps a client-side search engine library to expose search functionality to the application.
class SearchService
  constructor: (@$q) ->
    @_dbName = 'cards'
    @_searchEngine = new fullproof.BooleanEngine();
    @_engineReadyDeferred = @$q.defer()
    @_engineReady = @_engineReadyDeferred.promise
    window.search = @search

  indexCards: (@cards) ->
    # Store a map of cards by their title, for later mapping
    @_cardsByTitle = _.object(_.zip(_.pluck(cards, 'title'), cards))

    initializer = (injector, callback) =>
      text = ([ title, text, type, flavor, faction ].join(' ') for { title, text, type, flavor, faction } in cards)
      values = (title for { title } in cards)
      injector.injectBulk(text, values, callback)

    normalIndex  = _.extend( @_normalIndex(), initializer: initializer)
    stemmedIndex = _.extend(@_stemmedIndex(), initializer: initializer)

    @_searchEngine.open([ normalIndex, stemmedIndex ],
      (=>
        console.info 'Search engine ready'
        @_engineReadyDeferred.resolve(true)),
      (=> console.error 'Search engine failed to initialize'));

  # Retuns a promise that will resolve to an array of cards matching the provided query.
  search: (query) =>
    deferred = @$q.defer()
    @_engineReady.then => # Wait until the engine is ready before attempting a search
      @_searchEngine.lookup(query, (resultSet) =>
        resultSet = data: [] unless resultSet
        cards = @_mapTitlesToCards(resultSet.data)
        console.debug('cards', cards)
        deferred.resolve(cards))
    deferred.promise

  _mapTitlesToCards: (cardTitles) ->
    (@_cardsByTitle[title] for title in cardTitles)

  # Simple index for quick/exact matching
  _normalIndex: ->
    name: "normalIndex"
    analyzer: new fullproof.StandardAnalyzer([
      fullproof.normalizer.to_lowercase_nomark,
      fullproof.normalizer.remove_duplicate_letters,
      fullproof.english.porter_stemmer
    ])
    capabilities: new fullproof.Capabilities().setUseScores(false).setDbName(@_dbName)

  # More complex index, including a metaphone analyzer
  _stemmedIndex: ->
    name: "stemmedIndex"
    analyzer: new fullproof.StandardAnalyzer([
      fullproof.normalizer.to_lowercase_nomark,
      fullproof.english.metaphone
    ])
    capabilities: new fullproof.Capabilities().setUseScores(false).setDbName(@_dbName)

# Register the service
angular.module('deckBuilder').service 'searchService', SearchService
