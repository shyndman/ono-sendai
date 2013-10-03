'use strict';

angular.module('deckBuilder')
  .directive('numericFilter', (cardService) ->
    templateUrl: '/views/directives/nr-numeric-filter.html'
    restrict: 'E'
    require: 'ngModel'
    link: (scope, element, attrs, ctrl) ->
      console.log ctrl
      scope.comparisonOperators = cardService.comparisonOperators
      # element.text 'this is the nrNumericFilter directive'
  )
