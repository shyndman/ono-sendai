angular.module('onoSendai')
  .directive('nrGroupingSelector', (groupingUI, urlStateService) ->
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

      $scope.selectGroup = (grouping) ->
        if !grouping? or grouping == $scope.selectedGrouping
          return

        $scope.selectedGrouping = grouping
        $scope.filter.groupByFields = grouping.groupByFields
        $scope.moreGroupingSelected = _.include($scope.moreGroupings, grouping)

      # React to external group changes
      $scope.$watch 'filter.groupByFields', groupByChanged = (groupByFields) ->
        $scope.selectGroup(groupingWithFields(groupByFields))
  )
