angular.module('deckBuilder')

  # The all or one box is a set of buttons whose behaviour is somewhere in between those of checkboxes and radiobuttons.
  # This set of controls sit in front of sit in front of an object model filled with boolean entries. Example:
  #
  # {
  #   a: true,
  #   b: true,
  #   c: true,
  #   ...
  # }
  #
  # The set of buttons can exist in two states:
  #
  #   1. A single button is "active", and its underlying boolean field in the model is true. All others are false.
  #   2. No buttons appear active, and all fields are true.
  #
  #
  .directive('uiAllOrOneBox', ->
    restrict: 'A'
    require: 'ngModel'
    link: (scope, element, attrs, ngModelCtrl) ->
      boolField = attrs.uiAllOrOneBox

      # Model -> UI
      ngModelCtrl.$render = ->
        flag =
          if _.all(ngModelCtrl.$modelValue, (bool) -> bool)
            false
          else
            ngModelCtrl.$modelValue[boolField]

        element.toggleClass('active', flag)

      homogenizeModel = (value) ->
        _.object(_.map(ngModelCtrl.$modelValue, (val, key) -> [key, value]))

      allTrues = ->
        homogenizeModel(true)

      allFalses = ->
        homogenizeModel(false)

      # UI -> Model
      element.on 'click', ->
        newModelVal =
          if element.hasClass('active') # Set all booleans to true
            allTrues()
          else
            oneTrue = allFalses()
            oneTrue[attrs.uiAllOrOneBox] = true
            oneTrue

        scope.$apply ->
          ngModelCtrl.$setViewValue(newModelVal)
          ngModelCtrl.$render()
  )
