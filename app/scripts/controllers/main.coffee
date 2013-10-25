
angular.module('deckBuilder')
  .controller('MainCtrl', ($scope, filterDefaults) ->
    $scope.filter = filterDefaults
    $scope.grid = zoom: 0.5)
