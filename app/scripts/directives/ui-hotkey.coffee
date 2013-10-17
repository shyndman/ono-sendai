angular.module('deckBuilder')
  .directive('uiHotkey', () ->
    # TODO Add display elements for showing available hotkeys on screen
    jwerty.key('tab', ->)

    restrict: 'A'
    link: (scope, element, attrs) ->
      console.info "Binding element to #{attrs.uiHotkey}", element

      focusElement = (e) ->
        element.focus().select()
        e.preventDefault()

      jwerty.key(attrs.uiHotkey, focusElement)
  )
