
angular.module('deckBuilder')
  .controller('MainCtrl', ($scope, filterDefinitions) ->
    $scope.filter = filterDefinitions)
