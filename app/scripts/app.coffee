angular.module('deckBuilderApp', [])
  .config(($routeProvider) ->
    $routeProvider
      .when('/',
        templateUrl: 'views/main.html',
        controller: 'MainCtrl'
      )
      .otherwise(redirectTo: '/'))
