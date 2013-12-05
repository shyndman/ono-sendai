# Based on the work by the angular-ui team (angular-bootstrap)
angular.module('onoSendai')
  .directive('dropdownToggle', ($document, $location) ->
    openElement = null
    closeMenu   = -> # noop, until replaced

    {
      restrict: 'CA'
      link: (scope, element, attrs) ->
        scope.$watch('$location.path', -> closeMenu())
        element.parent().bind('click', -> closeMenu())
        element.bind('click', (event) ->
          elementWasOpen = element == openElement

          event.preventDefault();
          event.stopPropagation();

          closeMenu() if openElement

          if !elementWasOpen
            dropdown = element.parent()
            dropdown.addClass('open')

            # Focus the appropriate element
            value = element.text().trim()
            focusLink = null
            for link in dropdown.find('.dropdown-menu a')
              if $(link).text().trim() == value
                focusLink = $(link)
                break

            focusLink ?= dropdown.find('.dropdown-menu a:first')
            focusLink.focus()

            openElement = element
            closeMenu = (event) ->
              if event
                event.preventDefault()
                event.stopPropagation()

              $document.unbind('click', closeMenu)
              element.parent().removeClass('open')
              closeMenu = _.noop
              openElement = null

            $document.bind('click', closeMenu))
    })

  # Handles keyboard input for the dropdown menu
  .directive('dropdownMenu', ($document) ->
    restrict: 'CA'
    link: (scope, element, attrs) ->
      parent = element.parent()
      toggle = parent.find('.dropdown-toggle')

      element.keydown (e) ->
        return unless jwerty.is('esc/up/down/enter/space', e)

        e.preventDefault()
        e.stopPropagation()

        return if element.is('.disabled, :disabled')

        isActive = parent.hasClass('open')

        if jwerty.is('esc', e)
          toggle.click()
          toggle.focus()
          return
        else if jwerty.is('enter/space', e)
          $(e.target).click()
          return

        items = element.find('a')
        return if _.isEmpty(items)

        index = items.index($document.attr('activeElement'))
        if jwerty.is('up', e) and index > 0
          index--
        else if jwerty.is('down', e) and index < items.length - 1
          index++
        items.eq(index).focus()

    )
