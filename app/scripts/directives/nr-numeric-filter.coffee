'use strict';

angular.module('deckBuilder')
  .directive('numericFilter', (cardService) ->
    templateUrl: '/views/directives/nr-numeric-filter.html'
    scope:
      filter: '=filterAttr'
      placeholder: '@placeholder'
      id: '@id'
    restrict: 'E'
    link: (scope, element, attrs) ->
      scope.comparisonOperators = cardService.comparisonOperators
  )
