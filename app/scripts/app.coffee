_.mixin(_.str.exports()); # Make underscore.string functions available under the _ namespace

angular.module('deckBuilder', ['ngRoute'])
  .config(($locationProvider, $routeProvider) ->
    $locationProvider.html5Mode(true)
    $routeProvider
      .when('/',
        templateUrl: 'views/main.html',
        controller: 'MainCtrl')
      .otherwise(redirectTo: '/'))
