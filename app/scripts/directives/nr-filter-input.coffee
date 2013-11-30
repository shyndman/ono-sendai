'use strict'

angular.module('onoSendaiApp')
  .directive('nrFilterInput', () ->
    template: '<div></div>'
    restrict: 'E'
    link: (scope, element, attrs) ->
      element.text 'this is the nrFilterInput directive'
  )
