describe 'Service: NrCostToBreakCalculator', () ->

  # load the service's module
  beforeEach module 'onoSendaiApp'

  # instantiate service
  NrCostToBreakCalculator = {}
  beforeEach inject (_NrCostToBreakCalculator_) ->
    NrCostToBreakCalculator = _NrCostToBreakCalculator_

  it 'should do something', () ->
    expect(!!NrCostToBreakCalculator).toBe true
