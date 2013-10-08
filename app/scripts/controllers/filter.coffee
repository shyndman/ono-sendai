'use strict'

angular.module('deckBuilder')
  .controller('FilterCtrl', ($scope, filterUI) ->
    $scope.filterUI = filterUI
    $scope.filter.selectedGroup = _.findWhere(filterUI, name: 'general')

    $scope.selectGroup = (group) ->
      $scope.filter.selectedGroup = group

      if group.name is 'general'
        $scope.filter.primaryGrouping = 'faction'
        $scope.filter.secondaryGrouping = 'type'
      else
        $scope.filter.primaryGrouping = 'type'
        $scope.filter.secondaryGrouping = 'faction'

    $scope.isActiveGroup = (group, selectedGroup) ->
      group.name is selectedGroup.name

    $scope.isGroupShown = (group) ->
      true

    $scope.areFieldsShown = (group, selectedGroup) ->
      (group.name is 'general' and !selectedGroup.hideGeneral) or
      (selectedGroup.name == group.name)
  )
