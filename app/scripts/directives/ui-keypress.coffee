keypressHelper = (event, scope, element, attrs, $parse) ->
  params = scope.$eval(attrs['ui'+_.capitalize(event)])

  # Prepare combinations for simple checking
  _.each params, (actionStr, keys) ->
    action = $parse(actionStr)
    element.bind event, jwerty.event(keys, (e) ->
      action(scope, $event: e))

# Returns the directive definition function for the provided event name
keyDirective = (event) ->
  ($parse) ->
    restrict: 'A'
    link: (scope, element, attrs) ->
      keypressHelper(event, scope, element, attrs, $parse)

angular.module('deckBuilder')
  .directive('uiKeydown',  ['$parse', keyDirective('keydown')])
  .directive('uiKeyup',    ['$parse', keyDirective('keyup')])
  .directive('uiKeypress', ['$parse', keyDirective('keypress')])
