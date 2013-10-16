'use strict'

describe 'Directive: nrNumericFilter', () ->

  # load the directive's module
  beforeEach module 'deckBuilder'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-numeric-filter></nr-numeric-filter>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrNumericFilter directive'
