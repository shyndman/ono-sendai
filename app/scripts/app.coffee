angular.module('deckBuilder', ['ngRoute'])
  .config(($locationProvider, $routeProvider) ->
    $locationProvider.html5Mode(true)
    $routeProvider
      .when('/',
        templateUrl: 'views/main.html',
        controller: 'MainCtrl'
      )
      .otherwise(redirectTo: '/'))
