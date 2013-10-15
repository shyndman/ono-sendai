angular.module('deckBuilder')
  .directive('nrNav', ->
    templateUrl: 'views/directives/nr-nav.html'
    replace: true
    restrict: 'E'
  )
