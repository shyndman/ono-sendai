'use strict'

angular.module('deckBuilder')
  .directive('uiLinkedCheckbox', ->
    activeClass = 'active'
    toggleEvent = 'click'

    restrict: 'A'
    require: 'ngModel'
    link: (scope, element, attrs, ngModelCtrl) ->
      # Model -> UI
      ngModelCtrl.$render = ->
        element.toggleClass(activeClass, angular.equals(ngModelCtrl.$modelValue, scope.$eval(attrs.btnRadio)))

      # UI -> Model
      element.bind toggleEvent, ->
        if !element.hasClass(activeClass)
          scope.$apply ->
            ngModelCtrl.$setViewValue(scope.$eval(attrs.btnRadio))
            ngModelCtrl.$render()
  )
