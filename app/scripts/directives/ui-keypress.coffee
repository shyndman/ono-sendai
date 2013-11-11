# Binds keyboard combinations to expressions, using Jwerty.
keypressHelper = (event, scope, element, attrs, $parse) ->
  params = scope.$eval(attrs['ui'+_.capitalize(event)])

  # Prepare combinations for simple checking
  _.each params, (action, keys) ->
    actionFn = $parse(action)
    element.on event, jwerty.event(keys, (e) ->
      scope.$apply ->
        actionFn(scope, $event: e))

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
