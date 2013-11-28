'use strict'

describe 'Filter: groupTitle', () ->

  # load the filter's module
  beforeEach module 'onoSendai'

  # initialize a new instance of the filter before each test
  groupTitle = {}
  beforeEach inject ($filter) ->
    groupTitle = $filter 'groupTitle'

  it 'should return the input prefixed with "groupTitle filter:"', () ->
    text = 'angularjs'
    expect(groupTitle text).toBe ('groupTitle filter: ' + text)
