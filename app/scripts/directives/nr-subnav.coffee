# Sub-navigation
angular.module('onoSendai')
  .directive('nrSubnav', ->
    templateUrl: '/views/directives/nr-subnav.html'
    replace: false
    restrict: 'E'
    controller: ($scope) ->
      $scope.isZoomVisible = ->
        $scope.uiState?.mainContent == 'cardGrid'
  )
