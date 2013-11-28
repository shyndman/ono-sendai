# Binds keyboard combinations to expressions, using Jwerty.
keypressHelper = (event, scope, element, attrs, $parse) ->
  params = scope.$eval(attrs['ui'+_.capitalize(event)])

  # Prepare combinations for simple checking
  _.each params, (actionOrOptions, keys) ->
    [ action, preventDefault, stopPropagation ] =
      if _.isObject(actionOrOptions)
        [ actionOrOptions.action, actionOrOptions.preventDefault, actionOrOptions.stopPropagation ]
      else
        [ actionOrOptions, false, false ]

    actionFn = $parse(action)
    element.on event, jwerty.event(keys, (e) ->
      e.preventDefault() if preventDefault
      e.stopPropagation() if stopPropagation

      # [todo] stopPropagation and preventDefault should be configurable
      scope.$apply ->
        actionFn(scope, $event: e))

# Returns the directive definition function for the provided event name
keyDirective = (event) ->
  ($parse) ->
    restrict: 'A'
    link: (scope, element, attrs) ->
      keypressHelper(event, scope, element, attrs, $parse)

angular.module('onoSendai')
  .directive('uiKeydown',  ['$parse', keyDirective('keydown')])
  .directive('uiKeyup',    ['$parse', keyDirective('keyup')])
  .directive('uiKeypress', ['$parse', keyDirective('keypress')])
