angular.module('onoSendai')
  .directive('main', ->
    lineScrollDelta = 40

    restrict: 'E'
    link: (scope, element, attrs) ->
      # Line scroll
      jwerty.key 'up',   -> element.scrollTop(element.scrollTop() - lineScrollDelta)
      jwerty.key 'down', -> element.scrollTop(element.scrollTop() + lineScrollDelta)

      # Page scroll
      jwerty.key 'page-up',   -> element.scrollTop(element.scrollTop() - element.height())
      jwerty.key 'page-down', -> element.scrollTop(element.scrollTop() + element.height())
  )
