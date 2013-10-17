angular.module('deckBuilder')
  .directive('uiHotkey', () ->
    # TODO Add display elements for showing available hotkeys on screen
    jwerty.key('tab', ->)

    restrict: 'A'
    link: (scope, element, attrs) ->
      console.info "Binding element to #{attrs.uiHotkey}", element

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
