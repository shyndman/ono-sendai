angular.module('onoSendai')
  .controller('FiltersCtrl', ($scope, filterUI, cardService) ->
    $scope.filterUI = filterUI
    factions = $scope.queryArgs.fieldFilters.faction
    cachedSets = null
    cachedReleasedSets = null

    # ~-~-~- SETS

    cardService.getSets().then updateSets = ([ sets, releasedSets ] = [ cachedSets, cachedReleasedSets ]) ->
      cachedSets = sets
      cachedReleasedSets = releasedSets

      # Filter out sets that aren't out yet
      visibleSets =
        if !$scope.queryArgs.fieldFilters.showSpoilers
          releasedSets
        else
          sets

      # Transform the sets for select2 consumption
      $scope.sets = _.map visibleSets, (set) ->
        id: set.id
        text: set.title

    # Change the sets list if the spoiler flag toggles
    $scope.$watch 'queryArgs.fieldFilters.showSpoilers', (flag) ->
      # [todo] Delete the set from the queryArgs if it isn't no longer available
      updateSets()


    # ~-~-~- ILLUSTRATORS AND SUBTYPES

    # Supply the subtypes for the current side
    cardService.ready().then updateSubtypes = ->
      side = $scope.queryArgs.side?.toLowerCase() ? 'all'
      subtypes = cardService.subtypes[side]
      $scope.subtypes = _.map subtypes, (st) ->
        id: st.id
        text: st.title

    # Supply the illustrators for the current side
    cardService.ready().then updateIllustrators = ->
      side = $scope.queryArgs.side?.toLowerCase() ? 'all'
      illustrators = cardService.illustrators[side]
      $scope.illustrators = _.map illustrators, (i) ->
        id: i.id
        text: i.title

    $scope.$watch 'queryArgs.side', sideChanged = (newSide, oldSide) ->
      # Ignore the first "change", because it screws with URL state
      # [todo] The !oldSide? condition exists to fix a bug when moving
      #        from the "all" side to a specific card subtype. This code
      #        should live elsewhere (like in the subnav code)
      if newSide is oldSide or !oldSide?
        return

      $scope.queryArgs.activeGroup = 'general'
      $scope.clearFactions()
      delete $scope.queryArgs.fieldFilters.subtype
      updateSubtypes()
      updateIllustrators()

    $scope.$watch('queryArgs.fieldFilters.faction', (factionsChanged = (newFactions) ->
      $scope.factionSelected = _.any factions, (flag) -> !flag
    ), true)

    findGroup = (groupName) ->
      _.findWhere(filterUI, name: groupName)

    clearExcludedFields = (groupName) ->
      _.each findGroup(groupName).hiddenGeneralFields ? [], (__, fieldName) ->
        fieldFilter = $scope.queryArgs.fieldFilters[fieldName]
        if fieldFilter.value?
          $scope.queryArgs.fieldFilters[fieldName].value = null

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
      if $scope.queryArgs.activeGroup isnt group
        $scope.queryArgs.activeGroup = group
        clearExcludedFields(group)
      else
        $scope.queryArgs.activeGroup = 'general'

    $scope.isActiveGroup = (group, activeGroup) ->
      if activeGroup
        group.name is activeGroup
      else
        false

    $scope.isGroupShown = (group, currentSide) ->
      !group.sideVisibility? or
      (
        _.isFunction(group.sideVisibility) and
        group.sideVisibility(currentSide)
      ) or
      group.sideVisibility == currentSide

    $scope.isFieldShown = (field, group, activeGroup, currentSide) ->
      (
        group.name == 'general' or
        activeGroup == group.name
      ) and
      (
        !field.sideVisibility? or
        (
          _.isFunction(field.sideVisibility) and
          field.sideVisibility(currentSide)
        ) or
        field.sideVisibility == currentSide
      )

    $scope.isFieldDisabled = (field, group, activeGroup, currentSide) ->
      group.name is 'general' and
      findGroup(activeGroup).hiddenGeneralFields?[field.name]

    $scope.fieldHasInput = (val) ->
      if _.isString(val)
        val.length > 0
      else if _.isNumber(val)
        true
      else
        false
  )
