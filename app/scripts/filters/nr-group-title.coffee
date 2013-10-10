angular.module('deckBuilder')
  .filter 'groupTitle', ->
    (input) ->
      switch input
        when 'Agenda', 'Asset', 'Operation', 'Upgrade', 'Event', 'Program', 'Resource'
          "#{input}s"
        when 'Identity'
          'Identities'
        else
          input
