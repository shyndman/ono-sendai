angular.module('deckBuilder')
  .controller('MainCtrl', ($scope, urlStateService) ->
    $scope.filter = urlStateService.generatedQueryArgs
    $scope.grid = zoom: 0.5)
