angular.module('deckBuilder')
  .directive('insetFilter', () ->
    template: '<div class="input"></div>'
    restrict: 'E'
    scope: {
      queryArg: '=queryArg'
      placeholder: '@'
      id: '@'
    }
    link: (scope, element, attrs) ->
      element.removeAttr('id')

      # This is a function because select2 replaces its target with its own content, and always want
      # to point to the current .input element.
      inputElement = element.find('.input')

      # Attach an ID for the label
      inputElement.attr('id', scope.id)

      # Select2-ify the input element
      inputElement.select2(
        placeholder: scope.placeholder
        # Hides the search field
        # minimumResultsForSearch: -1
        data: [ id: 1, text: '123' ])


  )
