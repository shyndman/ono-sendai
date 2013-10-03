# Based on the work by the angular-ui team (angular-bootstrap)
angular.module('deckBuilder')
  .directive('dropdownToggle', ($document, $location) ->
    openElement = null
    closeMenu   = -> # noop

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
            element.parent().addClass('open')
            openElement = element
            closeMenu = (event) ->
              if event
                event.preventDefault()
                event.stopPropagation()

              $document.unbind('click', closeMenu)
              element.parent().removeClass('open')
              closeMenu = angular.noop
              openElement = null

            $document.bind('click', closeMenu))
    }
  )
