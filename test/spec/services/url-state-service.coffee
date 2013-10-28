'use strict'

describe 'Service: urlStateService', () ->

  # load the service's module
  beforeEach module 'deckBuilderApp'

  # instantiate service
  urlStateService = {}
  beforeEach inject (_urlStateService_) ->
    urlStateService = _urlStateService_

  it 'should do something', () ->
    expect(!!urlStateService).toBe true
