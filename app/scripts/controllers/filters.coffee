angular.module('onoSendai')
  .controller('FiltersCtrl', ($scope, filterUI, cardService) ->
    $scope.filterUI = filterUI
    factions = $scope.filter.fieldFilters.faction
    cachedSets = null
    cachedReleasedSets = null

    # ~-~-~- SETS

    cardService.getSets().then updateSets = ([ sets, releasedSets ] = [ cachedSets, cachedReleasedSets ]) ->
      cachedSets = sets
      cachedReleasedSets = releasedSets

      # Filter out sets that aren't out yet
      visibleSets =
        if !$scope.filter.fieldFilters.showSpoilers
          releasedSets
        else
          sets

      # Transform the sets for select2 consumption
      $scope.sets = _.map visibleSets, (set) ->
        id: set.id
        text: set.title

    # Change the sets list if the spoiler flag toggles
    $scope.$watch 'filter.fieldFilters.showSpoilers', (flag) ->
      # [todo] Delete the set from the queryArgs if it isn't no longer available
      updateSets()


    # ~-~-~- ILLUSTRATORS AND SUBTYPES

    # Supply the subtypes for the current side
    cardService.ready().then updateSubtypes = ->
      side = $scope.filter.side?.toLowerCase() ? 'all'
      subtypes = cardService.subtypes[side]
      $scope.subtypes = _.map subtypes, (st) ->
        id: st.id
        text: st.title

    # Supply the illustrators for the current side
    cardService.ready().then updateIllustrators = ->
      side = $scope.filter.side?.toLowerCase() ? 'all'
      illustrators = cardService.illustrators[side]
      console.log 'SIDE', side, cardService.illustrators, illustrators
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

    clearExcludedFields = (groupName) ->
      _.each findGroup(groupName).hiddenGeneralFields ? [], (__, fieldName) ->
        fieldFilter = $scope.filter.fieldFilters[fieldName]
        if fieldFilter.value?
          $scope.filter.fieldFilters[fieldName].value = null

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
        clearExcludedFields(group)
      else
        $scope.filter.activeGroup = 'general'

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
      group.name is 'general' and findGroup(activeGroup).hiddenGeneralFields?[field.name]
  )
