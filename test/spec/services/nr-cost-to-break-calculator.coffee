'use strict'

describe 'Service: NrCostToBreakCalculator', () ->

  # load the service's module
  beforeEach module 'DeckbuilderApp'

  # instantiate service
  NrCostToBreakCalculator = {}
  beforeEach inject (_NrCostToBreakCalculator_) ->
    NrCostToBreakCalculator = _NrCostToBreakCalculator_

  it 'should do something', () ->
    expect(!!NrCostToBreakCalculator).toBe true
