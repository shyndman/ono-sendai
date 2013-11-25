angular.module('deckBuilder')
  .directive('insetFilter', () ->
    template: '<div class="input"></div>'
    restrict: 'E'
    scope: {
      placeholder: '@'
    }
    link: (scope, element, attrs) ->
      element.find('.input').select2(
        placeholder: scope.placeholder
        data: [ id: 1, text: '123' ])
  )
