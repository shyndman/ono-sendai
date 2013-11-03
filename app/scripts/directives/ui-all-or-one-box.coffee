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
  .directive('uiAllOrOneBox', ($parse) ->
    restrict: 'A'
    require: 'ngModel'
    link: (scope, element, attrs, ngModelCtrl) ->
      getParentModel = $parse(attrs.uiAllOrOneBox)
      field = attrs.uiAllOrOneBoxField

      # Model -> UI
      ngModelCtrl.$render = ->
        parentModel = getParentModel(scope)
        flag =
          if _.all(parentModel, (bool) -> bool)
            false
          else
            ngModelCtrl.$modelValue
        element.toggleClass('active', flag)

      # UI -> Model
      #   TODO This seriously makes no sense. I'm completely circumventing the $setViewValue system in order
      #        to make this work properly.
      element.on 'click', ->
        parentModel = getParentModel(scope)
        if element.hasClass('active') # Set all booleans to true
          parentModel[key] = true for key, val of parentModel
        else
          parentModel[key] = false for key, val of parentModel
          parentModel[field] = true

        scope.$apply ->
          ngModelCtrl.$render()
  )
