describe 'Filter: nrCardUrl', () ->

  # load the filter's module
  beforeEach module 'deckBuilder'

  # initialize a new instance of the filter before each test
  nrCardUrl = {}
  beforeEach inject ($filter) ->
    nrCardUrl = $filter 'cardUrl'

  it 'should return the input prefixed with "nrCardUrl filter:"', () ->
    text = 'angularjs'
    expect(nrCardUrl text).toBe ('nrCardUrl filter: ' + text)
