'use strict'

describe 'Directive: nrSettings', () ->

  # load the directive's module
  beforeEach module 'onoSendaiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-settings></nr-settings>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrSettings directive'
