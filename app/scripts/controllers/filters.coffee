angular.module('onoSendai')
  .controller('FiltersCtrl', ($scope, filterUI, cardService) ->
    $scope.filterUI = filterUI
    generalGroup = _.findWhere(filterUI, name: 'general')
    factions = $scope.filter.fieldFilters.faction

    # Supply the sets
    cardService.getSets().then (sets) ->
      # Filter out sets that aren't out yet
      now = new Date().getTime()
      setsToDate = _.filter sets, (set) ->
        if set.released?
          new Date(set.released).getTime() < now
        else
          false

      # Transform the sets for select2 consumption
      $scope.sets = _.map setsToDate, (set) ->
        id: set.id
        text: set.title

    # Supply the subtypes for the current side
    cardService.ready().then updateSubtypes = ->
      subtypes = cardService.subtypes[$scope.filter.side.toLowerCase()]
      $scope.subtypes = _.map subtypes, (st) ->
        id: st.id
        text: st.title

    $scope.$watch 'filter.side', sideChanged = (newSide, oldSide) ->
      # Ignore the first "change", because it screws with URL state
      return if newSide is oldSide

      $scope.filter.activeGroup = generalGroup
      factions[key] = true for key, val of factions
      delete $scope.filter.fieldFilters.subtype
      updateSubtypes()

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
        $scope.filter.activeGroup = generalGroup

    $scope.isActiveGroup = (group, activeGroup) ->
      if activeGroup
        group.name is activeGroup.name
      else
        false

    $scope.isGroupShown = (group, currentSide) ->
      if group.side?
        group.side == currentSide
      else
        true

    $scope.isFieldShown = (field, group, activeGroup, currentSide) ->
      group.name is 'general' or ( # General fields are always shown...
        activeGroup.name == group.name and # ...so are the active group fields...
        (field.side is undefined or field.side == currentSide) # ...but are sometimes filtered if they have a side
      )

    $scope.isFieldDisabled = (field, group, activeGroup, currentSide) ->
      group.name is 'general' and activeGroup.hiddenGeneralFields?[field.name]
  )
