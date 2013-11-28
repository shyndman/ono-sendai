'use strict'

describe 'Directive: uiLinkedCheckbox', () ->

  # load the directive's module
  beforeEach module 'onoSendaiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<ui-linked-checkbox></ui-linked-checkbox>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the uiLinkedCheckbox directive'
