describe 'Directive: nrCardGrid', () ->

  # load the directive's module
  beforeEach module 'deckBuilder'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<nr-card-grid></nr-card-grid>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the nrCardGrid directive'
