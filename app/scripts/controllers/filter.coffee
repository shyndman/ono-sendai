angular.module('deckBuilder')
  .controller('FilterCtrl', ($scope, filterUI) ->
    $scope.filterUI = filterUI
    generalGroup = _.findWhere(filterUI, name: 'general')
    $scope.filter.activeGroup = generalGroup

    $scope.$watch 'filter.side', (newSide) ->
      $scope.filter.activeGroup = generalGroup
      $scope.filter.primaryGrouping = 'faction'
      $scope.filter.secondaryGrouping = 'type'

    $scope.activateGroup = (group) ->
      $scope.filter.activeGroup = group

      if group.name is 'general'
        $scope.filter.primaryGrouping = 'faction'
        $scope.filter.secondaryGrouping = 'type'
      else
        $scope.filter.primaryGrouping = 'type'
        $scope.filter.secondaryGrouping = 'faction'

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
      if activeGroup
        (group.name is 'general' and !activeGroup.hiddenGeneralFields?[field.name]) or
        (
          activeGroup.name == group.name and
          (field.side is undefined or field.side == currentSide)
        )
      else
        false
  )
