'use strict'

describe 'Service: lunrService', () ->

  # load the service's module
  beforeEach module 'deckBuilderApp'

  # instantiate service
  lunrService = {}
  beforeEach inject (_lunrService_) ->
    lunrService = _lunrService_

  it 'should do something', () ->
    expect(!!lunrService).toBe true
