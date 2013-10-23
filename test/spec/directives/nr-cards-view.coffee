describe 'Directive: nrCardsView', () ->

  # load the directive's module
  beforeEach module 'deckBuilder'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-cards-grid></nr-cards-grid>'
    element = $compile(element) scope
