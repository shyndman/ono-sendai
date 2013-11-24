keyToJwertyCombo = (key) ->
  switch key
    when '<'
      'shift+,'
    when '>'
      'shift+.'
    when '!'
      'shift+1'
    else
      key

angular.module('deckBuilder')
  .directive('numericFilter', ($timeout, cardService) ->
    templateUrl: '/views/directives/nr-numeric-filter.html'
    scope:
      filter: '=filterAttr'
      placeholder: '@'
      id: '@'
      max: '@'
      outerDisabled: '@uiDisabled'
    restrict: 'E'
    link: (scope, element, attrs) ->
      scope.comparisonOperators = _.pluck(cardService.comparisonOperators, 'display')
      inputElement = element.find('input')
      lastVal = scope.filter.value

      inputElement.keydown (e) ->
        e.stopPropagation() # We always want to stop the bubble
        # Erase the value if the user presses escape with the numeric input focused
        if jwerty.is('esc', e)
          scope.$apply -> scope.filter.value = undefined

      # All the user to type operators into the input field to change the operator dropdown value
      _.each cardService.comparisonOperators, (op) ->
        keys = op.typed.split('').map(keyToJwertyCombo).join(',')
        inputElement.keydown(jwerty.event(keys, (e) ->
          # Change the operator
          scope.$apply ->
            scope.filter.operator = op.display
          # Restore the numeric value
          $timeout ->
            inputElement.val(lastVal)
            inputElement.trigger('input')
            inputElement.trigger('change')))

      # Focus the numeric input whenever the operator changes
      firstChange = true # This watch is fired immediately, so ignore the first change
      scope.$watch 'filter.operator', (newVal, oldVal) ->
        if firstChange
          firstChange = false
        else
          inputElement.focus()

      scope.$watch 'filter.value', (newVal) ->
        if inputElement[0].validity.valid
          lastVal = newVal

      scope.$watch 'outerDisabled', (newVal) ->
        scope.uiDisabled =
          if newVal is 'true'
            true
          else
            false
  )
