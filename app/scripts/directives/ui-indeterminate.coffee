angular.module('onoSendai')
  .directive('uiIndeterminate', ->
    restrict: 'A'
    link: (scope, element, attrs) ->
      scope.$watch attrs.uiIndeterminate, (flag) ->
        element.prop('indeterminate', flag)
  )
