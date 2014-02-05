angular.module('onoSendai')
  .controller('FiltersCtrl', ($scope, filterUI, cardService) ->
    $scope.filterUI = filterUI
    factions = $scope.filter.fieldFilters.faction
    cachedSets = null

    # ~-~-~- SETS

    cardService.getSets().then updateSets = (sets = cachedSets) ->
      cachedSets = sets

      # Filter out sets that aren't out yet
      visibleSets =
        if !$scope.filter.fieldFilters.showSpoilers
          now = new Date().getTime()
          _.filter sets, (set) ->
            if set.released?
              new Date(set.released).getTime() < now
            else
              false
        else
          sets

      # Transform the sets for select2 consumption
      $scope.sets = _.map visibleSets, (set) ->
        id: set.id
        text: set.title

    # Change the sets list if the spoiler flag toggles
    $scope.$watch 'filter.fieldFilters.showSpoilers', (flag) ->
      updateSets()


    # ~-~-~- ILLUSTRATORS AND SUBTYPES

    # Supply the subtypes for the current side
    cardService.ready().then updateSubtypes = ->
      subtypes = cardService.subtypes[$scope.filter.side.toLowerCase()]
      $scope.subtypes = _.map subtypes, (st) ->
        id: st.id
        text: st.title

    cardService.ready().then updateIllustrators = ->
      illustrators = cardService.illustrators[$scope.filter.side.toLowerCase()]
      $scope.illustrators = _.map illustrators, (i) ->
        id: i.id
        text: i.title

    $scope.$watch 'filter.side', sideChanged = (newSide, oldSide) ->
      # Ignore the first "change", because it screws with URL state
      return if newSide is oldSide

      $scope.filter.activeGroup = 'general'
      $scope.clearFactions()
      delete $scope.filter.fieldFilters.subtype
      updateSubtypes()
      updateIllustrators()

    $scope.$watch('filter.fieldFilters.faction', (factionsChanged = (newFactions) ->
      $scope.factionSelected = _.any factions, (flag) -> !flag
    ), true)

    findGroup = (groupName) ->
      _.findWhere(filterUI, name: groupName)

    $scope.clearFactions = ->
      for key, val of factions
        factions[key] = true

    $scope.labelledFieldId = (field) ->
      switch field.type
        when 'numeric'
          "#{field.name}-filter-operator"
        when 'search', 'inSet'
          "#{field.name}-filter"

    $scope.toggleGroup = (group) ->
      if $scope.filter.activeGroup isnt group
        $scope.filter.activeGroup = group
      else
        $scope.filter.activeGroup = 'general'

    $scope.isActiveGroup = (group, activeGroup) ->
      if activeGroup
        group.name is activeGroup
      else
        false

    $scope.isGroupShown = (group, currentSide) ->
      if group.side?
        group.side == currentSide
      else
        true

    $scope.isFieldShown = (field, group, activeGroup, currentSide) ->
      group.name is 'general' or ( # General fields are always shown...
        activeGroup == group.name and # ...so are the active group fields...
        (field.side is undefined or field.side == currentSide) # ...but are sometimes filtered if they have a side
      )

    $scope.isFieldDisabled = (field, group, activeGroup, currentSide) ->
      group.name is 'general' and findGroup(activeGroup).hiddenGeneralFields?[field.name]
  )
