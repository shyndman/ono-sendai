# groupName is always a string, because of how the grouping process works
groupTitle = (groupName, grouping) ->
  numericGroupName = parseInt(groupName)

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
      if !_.isNaN(numericGroupName)
        ret = "#{ groupName } Credit"
        ret += 's' if numericGroupName == 0 or numericGroupName > 1
        ret += ' to Trash' if grouping == 'trash'
        ret
      else
        ret = 'Cost N/A'
        ret = 'Trash ' + ret if grouping == 'trash'
        ret

    when 'minimumdecksize'
      if !_.isNaN(numericGroupName)
        "#{ groupName } Cards"
      else
        'Min. Deck Size N/A'

    when 'influencelimit'
      if !_.isNaN(numericGroupName)
        "#{ groupName } Influence Available"
      else
        'Available Influence N/A'

    when 'agendapoints'
      if !_.isNaN(numericGroupName)
        ret = "#{ groupName } Agenda Point"
        ret += 's' if numericGroupName == 0 or numericGroupName > 1
        ret
      else
        'Angenda Points N/A'

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

span = (contents, cls) ->
  "<span class=\"#{ cls }\">#{ contents }</span>"

# [todo] These filters suuuuck. Rewrite.
angular.module('onoSendai')
  .filter('primaryGroupTitle', ->
    (groupTitles, groupByFields) ->
      if groupByFields.length > 1
        groupTitle(groupTitles[1], groupByFields[1])
      else
        groupTitle(groupTitles[0], groupByFields[0])
    )
  .filter('secondaryGroupTitle', (cardService, dateFilter, $sce) ->
    (groupTitles, groupByFields) ->
      $sce.trustAsHtml(
        if groupByFields.length > 1
          groupTitle(groupTitles[0], groupByFields[0])
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
