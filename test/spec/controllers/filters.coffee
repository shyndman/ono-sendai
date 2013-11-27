'use strict'

describe 'Controller: FiltersCtrl', () ->

  # load the controller's module
  beforeEach module 'onoSendai'

  FiltersCtrl = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    FiltersCtrl = $controller 'FiltersCtrl', {
      $scope: scope
    }

  it 'should attach a list of awesomeThings to the scope', () ->
    expect(scope.awesomeThings.length).toBe 3
