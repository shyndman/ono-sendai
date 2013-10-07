
angular.module('deckBuilder')
  .controller('MainCtrl', ($scope, filterDefaults) ->
    $scope.filter = filterDefaults)
