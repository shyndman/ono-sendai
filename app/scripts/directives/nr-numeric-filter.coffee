angular.module('deckBuilder')
  .directive('numericFilter', (cardService) ->
    templateUrl: '/views/directives/nr-numeric-filter.html'
    scope:
      filter: '=filterAttr'
      placeholder: '@'
      id: '@'
      max: '@'

    restrict: 'E'
    link: (scope, element, attrs) ->
      scope.comparisonOperators = cardService.comparisonOperators

      inputElement = element.find('input')

      # Erase the value if the user presses escape with the numeric input focused
      inputElement.keydown(jwerty.event('esc', ->
        scope.$apply ->
          scope.filter.value = undefined))

      # Focus the numeric input whenever the operator changes
      firstChange = true # This watch is fired immediately, so ignore the first change
      scope.$watch 'filter.operator', (newVal, oldVal) ->
        if firstChange
          firstChange = false
        else
          inputElement.focus()
  )
