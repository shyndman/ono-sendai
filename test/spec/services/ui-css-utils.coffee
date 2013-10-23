describe 'Service: CssUtils', () ->

  # load the service's module
  beforeEach module 'deckBuilder'

  # instantiate service
  uiCssUtils = {}
  beforeEach inject (_uiCssUtils_) ->
    uiCssUtils = _uiCssUtils_

  it 'should do something', () ->
    expect(!!uiCssUtils).toBe true
