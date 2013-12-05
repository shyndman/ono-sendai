# Top navigation
angular.module('onoSendai')
  .directive('nrNav', ->
    templateUrl: '/views/directives/nr-nav.html'
    replace: false
    restrict: 'E'
  )
