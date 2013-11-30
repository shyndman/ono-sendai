
angular.module('onoSendai')
  # Captures and stops the propagation of key presses that also have top-level actions
  # (card forward/back).
  .directive('filterInput', ->
    restrict: 'A'
    link: (scope, element, attrs) ->
      element.keydown jwerty.event('esc/left/right', (e) -> e.stopPropagation())
  )
