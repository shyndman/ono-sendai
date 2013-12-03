# Sub-navigation
angular.module('onoSendai')
  .directive('nrSubnav', (groupingUI) ->
    templateUrl: '/views/directives/nr-subnav.html'
    replace: false
    restrict: 'E'
    controller: ($scope) ->
      $scope.groupingUI = groupingUI
  )
