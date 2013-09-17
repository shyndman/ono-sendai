'use strict'

describe 'Filter: cardFilter', () ->

  # load the filter's module
  beforeEach module 'deckBuilder'

  # initialize a new instance of the filter before each test
  cardFilter = {}
  beforeEach inject ($filter) ->
    cardFilter = $filter 'cardFilter'

  it 'should return the input prefixed with "cardFilter filter:"', () ->
    text = 'angularjs'
    expect(cardFilter text).toBe ('cardFilter filter: ' + text)
