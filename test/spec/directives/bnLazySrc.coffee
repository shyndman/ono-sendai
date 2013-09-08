'use strict'

describe 'Directive: bnLazySrc', () ->

  # load the directive's module
  beforeEach module 'deckBuilderApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<bn-lazy-src></bn-lazy-src>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the bnLazySrc directive'
