'use strict'

describe 'Directive: nrCardView', () ->

  # load the directive's module
  beforeEach module 'onoSendaiApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-card-view></nr-card-view>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrCardView directive'
