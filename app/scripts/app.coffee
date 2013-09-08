angular.module('deckBuilderApp', ['ngRoute'])
  .config(($routeProvider) ->
    $routeProvider
      .when('/',
        templateUrl: 'views/main.html',
        controller: 'MainCtrl'
      )
      .otherwise(redirectTo: '/'))
