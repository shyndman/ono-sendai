describe 'Filter: nrPluralizeType', () ->

  # load the filter's module
  beforeEach module 'deckBuilder'

  # initialize a new instance of the filter before each test
  nrPluralizeType = {}
  beforeEach inject ($filter) ->
    nrPluralizeType = $filter 'pluralizeType'

  it 'should return the input prefixed with "nrPluralizeType filter:"', () ->
    text = 'angularjs'
    expect(nrPluralizeType text).toBe ('nrPluralizeType filter: ' + text)
