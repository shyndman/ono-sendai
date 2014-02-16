angular.module('onoSendai')
  .directive('groupSelector', (groupingUI, urlStateService) ->
    templateUrl: '/views/directives/nr-grouping-selector.html'
    restrict: 'E'
    controller: ($scope) ->
      # Returns the grouping with the specified groupByFields
      groupingWithFields = (groupByFields) ->
        _.find groupingUI, (grouping) ->
          angular.equals(grouping.groupByFields, groupByFields)

      $scope.allGroupings = groupingUI
      $scope.primaryGroupings = _.filter(groupingUI, (grouping) -> !grouping.inMore?)
      $scope.moreGroupings = _.filter(groupingUI, (grouping) -> grouping.inMore?)

      $scope.selectGroup = (group) ->
        $scope.selectedGrouping = group
        $scope.filter.groupByFields = group.groupByFields
        $scope.moreGroupingSelected = _.include($scope.moreGroupings, group)

      # React to URL state changes, that may change the selected group
      $scope.$on 'urlStateChange', urlChanged = ->
        $scope.selectGroup(groupingWithFields(urlStateService.queryArgs.groupByFields))

      # Set initial state
      $scope.selectGroup(groupingWithFields($scope.filter.groupByFields))
  )
