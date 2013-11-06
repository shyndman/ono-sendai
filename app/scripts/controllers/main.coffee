angular.module('deckBuilder')
  .controller('MainCtrl', ($scope, $http, urlStateService) ->
    $scope.filter = urlStateService.generatedQueryArgs
    $scope.grid = zoom: 0.5
    $http.get('/data/version.json').success((data) ->
      $scope.version = data.version))
