# [todo] These filters are soooo ugly. Rethink, maybe rewrite.

# groupName is always a string, because of how the grouping process works
groupTitle = (groupName, grouping) ->
  numGroupName = parseInt(groupName)

  switch grouping
    when 'type'
      switch groupName
        when 'Agenda', 'Asset', 'Operation', 'Upgrade', 'Event', 'Program', 'Resource'
          "#{ groupName }s"
        when 'Identity'
          'Identities'
        else
          groupName

    when 'cost', 'trash'
      if !_.isNaN(numGroupName)
        ret = "#{ groupName } Credit"
        ret += 's' if numGroupName == 0 or numGroupName > 1
        ret += ' to Trash' if grouping == 'trash'
        ret
      else
        ret = 'Cost N/A'
        ret = 'Trash ' + ret if grouping == 'trash'
        ret

    when 'minimumdecksize'
      if !_.isNaN(numGroupName)
        "#{ groupName } Cards"
      else
        'Min. Deck Size N/A'

    when 'influencelimit'
      if !_.isNaN(numGroupName)
        "#{ groupName } Influence Available"
      else
        'Available Influence N/A'

    when 'strength'
      groupName = parseInt(groupName)
      if !_.isNaN(groupName)
        "#{ groupName } Strength"
      else
        'Strength N/A'

    when 'factioncost'
      if groupName != ''
        "#{ groupName } Influence"
      else
        "Influence N/A"

    when 'illustrator'
      if groupName != ''
        groupName
      else
        'None Listed'
    else
      groupName

agendaGroupTitle = ([ advancementCost, points ]) ->
  numPoints = parseInt(points)

  if !_.isNaN(numPoints)
    "#{ advancementCost }/#{ points } Agendas"
  else
    'Angenda Points N/A'

span = (contents, cls) ->
  "<span class=\"#{ cls }\">#{ contents }</span>"

AGENDA_GROUP_BYS = [ 'advancementcost', 'agendapoints' ]

angular.module('onoSendai')
  .filter('primaryGroupTitle', ->
    (groupTitles, groupByFields) ->
      # Special case for the agenda grouping
      if angular.equals(groupByFields, AGENDA_GROUP_BYS)
        agendaGroupTitle(groupTitles)
      else if groupByFields.length > 1
        groupTitle(groupTitles[1], groupByFields[1])
      else
        groupTitle(groupTitles[0], groupByFields[0])
    )
  .filter('secondaryGroupTitle', (cardService, dateFilter, $sce) ->
    (groupTitles, groupByFields) ->
      $sce.trustAsHtml(
        # The agenda group by has no secondary
        if angular.equals(groupByFields, AGENDA_GROUP_BYS)
          ''
        # If we're grouping by multiple fields, use the first as the seconandary
        # ie. [Jinteki, Identity] would return Jinteki as its secondary title.
        else if groupByFields.length > 1
          groupTitle(groupTitles[0], groupByFields[0])
        # If we're dealing with sets, we print out the cycle and the release date
        else if groupByFields[0] == 'setname' and
               (set = cardService.getSetByTitle(groupTitles[0]))?
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
