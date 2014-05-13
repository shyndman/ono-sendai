# Sub-navigation
angular.module('onoSendai')
  .directive('nrSubnav', ->
    templateUrl: '/views/directives/nr-subnav.html'
    replace: false
    restrict: 'E'
    controller: ($scope) ->
      $scope.isZoomVisible = ->
        $scope.uiState? and
        (
          $scope.uiState.mainContent == 'cardGrid' or
          $scope.uiState.mainContent == 'deckGrid'
        )
  )
