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
      if groupName isnt ''
        "#{ groupName } Influence"
      else
        "Influence N/A"
    else
      groupName

angular.module('deckBuilder')
  .filter('primaryGroupTitle', ->
    (groupTitles, groupings) ->
      if groupings.length > 1
        groupTitle(groupTitles[1], groupings[1])
      else
        groupTitle(groupTitles[0], groupings[0])
    )
  .filter('secondaryGroupTitle', ->
    (groupTitles, groupings) ->
      if groupings.length > 1
        groupTitle(groupTitles[0], groupings[0])
      else
        ''
    )
