angular.module('deckBuilder')
  .directive('nrSubnav', ->
    templateUrl: 'views/directives/nr-subnav.html'
    replace: true
    restrict: 'E'
  )
