keypressHelper = (event, scope, element, attrs) ->
  params = scope.$eval(attrs['ui'+_.capitalize(event)])

  # Prepare combinations for simple checking
  _.each params, (actionStr, keys) ->
    action = $parse(actionStr)
    element.bind event, jwerty.event(keys, (e) ->
      action(scope, $event: e))

# Returns the directive definition function for the provided event name
keyDirective = (event) ->
  ->
    restrict: 'A'
    link: (scope, element, attrs) ->
      keypressHelper(event, scope, element, attrs)

angular.module('deckBuilder')
  .directive('uiKeydown', keyDirective('keydown'))
  .directive('uiKeyup', keyDirective('keyup'))
  .directive('uiKeypress', keyDirective('keypress'))
