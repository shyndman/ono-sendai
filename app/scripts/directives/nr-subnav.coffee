angular.module('deckBuilder')
  .directive('nrSubnav', ->
    templateUrl: '/views/directives/nr-subnav.html'
    replace: false
    restrict: 'E'
  )
