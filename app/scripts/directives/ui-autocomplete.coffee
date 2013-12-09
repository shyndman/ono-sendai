'use strict'

angular.module('onoSendaiApp')
  .directive('uiAutocomplete', () ->
    template: '<div></div>'
    restrict: 'E'
    link: (scope, element, attrs) ->
      element.text 'this is the uiAutocomplete directive'
  )
