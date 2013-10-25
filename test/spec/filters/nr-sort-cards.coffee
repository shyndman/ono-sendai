'use strict'

describe 'Filter: nrSortCards', () ->

  # load the filter's module
  beforeEach module 'deckBuilder'

  # initialize a new instance of the filter before each test
  nrSortCards = {}
  beforeEach inject ($filter) ->
    nrSortCards = $filter 'nrSortCards'

  it 'should return the input prefixed with "nrSortCards filter:"', () ->
    text = 'angularjs'
    expect(nrSortCards text).toBe ('nrSortCards filter: ' + text)
