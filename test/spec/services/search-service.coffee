'use strict'

describe 'Service: searchService', () ->

  # load the service's module
  beforeEach module 'deckBuilder'

  # instantiate service
  searchService = {}
  beforeEach inject (_searchService_) ->
    searchService = _searchService_

  it 'should do something', () ->
    expect(!!searchService).toBe true
