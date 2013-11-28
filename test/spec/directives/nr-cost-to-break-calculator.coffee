'use strict'

describe 'Directive: nrCostToBreakCalculator', () ->

  # load the directive's module
  beforeEach module 'onoSendaiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-cost-to-break-calculator></nr-cost-to-break-calculator>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrCostToBreakCalculator directive'
