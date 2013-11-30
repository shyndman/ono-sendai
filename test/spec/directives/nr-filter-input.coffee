'use strict'

describe 'Directive: nrFilterInput', () ->

  # load the directive's module
  beforeEach module 'onoSendaiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-filter-input></nr-filter-input>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrFilterInput directive'
