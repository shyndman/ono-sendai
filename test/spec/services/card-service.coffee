'use strict'

describe 'Service: cardService', () ->

  beforeEach module 'deckBuilder'

  # instantiate service
  cardService = {}
  beforeEach inject (_cardService_) ->
    cardService = _cardService_

  it 'should exclude general fields if specified'
