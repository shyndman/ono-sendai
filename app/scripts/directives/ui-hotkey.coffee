angular.module('onoSendai')
  .directive('uiHotkey', ($log) ->
    # TODO Add display elements for showing available hotkeys on screen
    jwerty.key('tab', ->)

    restrict: 'A'
    link: (scope, element, attrs) ->
      $log.debug 'Binding element to %s %o', attrs.uiHotkey, element.get(0)

      # Focuses or clicks the hotkeyed element, depending on its type
      invokeHotkey = (e) ->
        e.preventDefault()
        if element.is('button, .btn')
          e.click()
        else
          element.focus().select()

      if attrs.uiHotkey
        jwerty.key(attrs.uiHotkey, invokeHotkey)
  )
