
angular.module('deckBuilder')
  .controller('MainCtrl', ($scope, urlStateService) ->
    $scope.filter = urlStateService.generatedFilter
    $scope.grid = zoom: 0.5)
