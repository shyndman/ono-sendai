angular.module('deckBuilder')
  .controller('FiltersCtrl', ($scope, filterUI) ->
    $scope.filterUI = filterUI
    generalGroup = _.findWhere(filterUI, name: 'general')
    factions = $scope.filter.fieldFilters.faction

    $scope.$watch 'filter.side', (newSide, oldSide) ->
      # Ignore the first "change", which isn't really true, and screws with URL state
      return if newSide is oldSide

      $scope.filter.activeGroup = generalGroup
      factions[key] = true for key, val of factions
      delete $scope.filter.fieldFilters.subtype

    $scope.labelledFieldId = (field) ->
      switch field.type
        when 'numeric'
          "#{field.name}-filter-operator"
        when 'search'
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
