'use strict'

describe 'Controller: FilterCtrl', () ->

  # load the controller's module
  beforeEach module 'deckBuilder'

  FilterCtrl = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    FilterCtrl = $controller 'FilterCtrl', {
      $scope: scope
    }

  it 'should attach a list of awesomeThings to the scope', () ->
    expect(scope.awesomeThings.length).toBe 3
