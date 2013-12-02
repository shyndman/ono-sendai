'use strict'

describe 'Directive: uiMain', () ->

  # load the directive's module
  beforeEach module 'onoSendaiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<ui-main></ui-main>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the uiMain directive'
