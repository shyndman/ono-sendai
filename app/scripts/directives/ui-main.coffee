angular.module('onoSendai')
  .directive('main', ->
    lineScrollDelta = 40

    restrict: 'E'
    link: (scope, element, attrs) ->
      jwerty.key 'up', -> element.scrollTop(element.scrollTop() - lineScrollDelta)
      jwerty.key 'down', -> element.scrollTop(element.scrollTop() + lineScrollDelta)
  )
