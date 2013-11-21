angular.module('deckBuilder')
  .filter 'pluralizeType', () ->
    (input) ->
      input = input.toLowerCase()
      switch input
        when 'identity'
          'identities'
        when 'ice', 'hardware'
          input
        else
          "#{ input }s"

