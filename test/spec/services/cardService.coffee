'use strict'

describe 'Service: cardService', () ->

  # load the service's module
  beforeEach module 'deckBuilder'

  # instantiate service
  cardService = {}
  beforeEach inject (_cardService_) ->
    cardService = _cardService_

  it 'should do something', () ->
    expect(!!cardService).toBe true
