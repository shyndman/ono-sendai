'use strict'

describe 'Service: searchService', () ->

  # load the service's module
  beforeEach module 'onoSendai'

  # instantiate service
  searchService = {}
  beforeEach inject (_searchService_) ->
    searchService = _searchService_

  it 'should do something', () ->
    expect(!!searchService).toBe true
