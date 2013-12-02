'use strict'

angular.module('onoSendaiApp')
  .directive('uiMain', () ->
    template: '<div></div>'
    restrict: 'E'
    link: (scope, element, attrs) ->
      element.text 'this is the uiMain directive'
  )
