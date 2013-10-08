_.mixin(_.str.exports()); # Make underscore.string functions available under the _ namespace

angular.module('deckBuilder', ['ngRoute', 'ui.bootstrap.buttons'])
  .config(($locationProvider, $routeProvider) ->
    $routeProvider
      .when('/',
        templateUrl: 'views/cards.html',
        controller: 'CardsCtrl')
      .otherwise(redirectTo: '/'))
