angular.module('onoSendai')
  .controller('CardViewCtrl', ->

  )
  .directive('cardView', ->
    templateUrl: '/views/directives/nr-card-view.html'
    restrict: 'E'
    controller: 'CardViewCtrl'
    scope: {
      card: '='
      queryResult: '='
    }
    link: (scope, element, attrs) ->

  )
