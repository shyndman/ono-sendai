'use strict'

describe 'Directive: nrSubnav', () ->

  # load the directive's module
  beforeEach module 'deckBuilderApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-subnav></nr-subnav>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrSubnav directive'
