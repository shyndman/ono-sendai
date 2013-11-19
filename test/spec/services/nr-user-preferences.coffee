describe 'Service: userPreferences', () ->

  # load the service's module
  beforeEach module 'deckBuilder'

  # instantiate service
  NrUserPreferences = {}
  beforeEach inject (_NrUserPreferences_) ->
    NrUserPreferences = _NrUserPreferences_

  it 'should do something', () ->
    expect(!!NrUserPreferences).toBe true
