
angular.module('onoSendai')
  # Captures and stops the propagation of key presses that also have top-level actions
  # (card forward/back).
  .directive('filterInput', ($window) ->
    isMac = !!($window.navigator?.userAgent.toLowerCase().indexOf('mac') != -1)

    restrict: 'A'
    link: (scope, element, attrs) ->
      [preventDefaultChord, stopPropagationChord] =
        if isMac
          [ 'ctrl+left/ctrl+right', 'alt+left/alt+right' ]
        else
          [ 'alt+left/alt+right', 'ctrl+left/ctrl+right' ]

      element.keydown jwerty.event(preventDefaultChord, (e) ->
        e.preventDefault())

      element.keydown jwerty.event("esc/left/right/#{ stopPropagationChord }", (e) ->
        e.stopPropagation())
  )
