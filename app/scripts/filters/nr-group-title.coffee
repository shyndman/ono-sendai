angular.module('deckBuilder')
  .filter 'groupTitle', ->
    (input, grouping) ->
      switch grouping
        when 'type'
          switch input
            when 'Agenda', 'Asset', 'Operation', 'Upgrade', 'Event', 'Program', 'Resource'
              "#{input}s"
            when 'Identity'
              'Identities'
            else
              input
        when 'cost'
          input = parseInt(input)
          if !_.isNaN(input)
            ret = "#{input} Credit"
            ret += 's' if input == 0 or input > 1
            ret
          else
            "Cost N/A"
        when 'factioncost'
          if input isnt 'undefined'
            "#{input} Influence"
          else
            "Influence N/A"
        else
          input
