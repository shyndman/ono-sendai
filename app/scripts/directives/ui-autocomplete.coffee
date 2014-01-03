angular.module('onoSendai')
  .directive('uiAutocomplete', () ->
    template: '<div></div>'
    restrict: 'E'
    link: (scope, element, attrs) ->
      element.text 'this is the uiAutocomplete directive'
  )
