
angular.module('onoSendai')
  # Captures and stops the propagation of key presses that also have top-level actions
  # (card forward/back, page up/down, etc.)
  .directive('filterInput', ($window, $log, $parse) ->
    isMac = !!($window.navigator?.userAgent.toLowerCase().indexOf('mac') != -1)
    select2FocusSelector = '.select2-focusser'


    restrict: 'A'
    link: (scope, element, attrs) ->
      [ preventDefaultChord, stopPropagationChord ] =
        if isMac
          [ 'ctrl+left/ctrl+right/ctrl+esc', 'alt+left/alt+right/alt+esc' ]
        else
          [ 'alt+left/alt+right/alt+esc', 'ctrl+left/ctrl+right/ctrl+esc' ]

      element.keydown jwerty.event(preventDefaultChord, (e) ->
        e.preventDefault())

      element.keydown jwerty.event("esc/left/right/up/down/page-up/page-down/#{ stopPropagationChord }", (e) ->
        e.stopPropagation())

      # Special case!
      #   Watch for the enter press on the select2 focusser element, if any. Otherwise the enter press will
      #   be swallowed up deeper down.
      element.add(select2FocusSelector).keydown jwerty.event('enter', (e) ->
        $(':focus').blur())
  )
