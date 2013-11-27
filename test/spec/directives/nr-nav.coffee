'use strict'

describe 'Directive: nrNav', () ->

  # load the directive's module
  beforeEach module 'onoSendai'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-nav></nr-nav>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrNav directive'
