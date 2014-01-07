describe 'Directive: uiPristineWhenEmpty', () ->

  # load the directive's module
  beforeEach module 'onoSendai'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
