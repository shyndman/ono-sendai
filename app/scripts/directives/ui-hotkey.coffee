angular.module('deckBuilder')
  .directive('uiHotkey', () ->
    # TODO Add display elements for showing available hotkeys on screen
    jwerty.key('tab', -> console.log 'Show hotkeys')


    restrict: 'A'
    link: (scope, element, attrs) ->
      console.log "Binding element to #{attrs.uiHotkey}", element

      focusElement = (e) ->
        element.focus()
        e.preventDefault()

      jwerty.key(attrs.uiHotkey, focusElement)
  )
