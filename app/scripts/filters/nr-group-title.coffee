# groupName is always a string, because of how the grouping process works
groupTitle = (groupName, grouping) ->
  switch grouping
    when 'type'
      switch groupName
        when 'Agenda', 'Asset', 'Operation', 'Upgrade', 'Event', 'Program', 'Resource'
          "#{ groupName }s"
        when 'Identity'
          'Identities'
        else
          groupName
    when 'cost'
      groupName = parseInt(groupName)
      if !_.isNaN(groupName)
        ret = "#{ groupName } Credit"
        ret += 's' if groupName == 0 or groupName > 1
        ret
      else
        "Cost N/A"
    when 'factioncost'
      if groupName != ''
        "#{ groupName } Influence"
      else
        "Influence N/A"
    when 'illustrator'
      if groupName != ''
        groupName
      else
        'None'
    else
      groupName

span = (contents, cls) ->
  "<span class=\"#{ cls }\">#{ contents }</span>"

angular.module('onoSendai')
  .filter('primaryGroupTitle', ->
    (groupTitles, groupings) ->
      if groupings.length > 1
        groupTitle(groupTitles[1], groupings[1])
      else
        groupTitle(groupTitles[0], groupings[0])
    )
  .filter('secondaryGroupTitle', (cardService, dateFilter, $sce) ->
    (groupTitles, groupings) ->
      $sce.trustAsHtml(
        if groupings.length > 1
          groupTitle(groupTitles[0], groupings[0])
        else if groupings[0] == 'setname'
          set = cardService.getSetByTitle(groupTitles[0])
          if set?
            dateStr =
              if set.released?
                dateFilter(set.released, 'MMM. y')
              else
                'Unreleased'

            cycleStr =
              if set.cycle?
                span("#{ set.cycle } Cycle", "cycle #{ set.cycle.toLowerCase() }-cycle") + " - "
              else
                ''

            cycleStr + dateStr
        else
          ''
      )
    )
