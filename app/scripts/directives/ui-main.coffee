angular.module('onoSendai')
  .directive('main', ->
    lineScrollDelta = 40

    restrict: 'E'
    link: (scope, element, attrs) ->
      scrollByFn = (amount) ->
        ->
          if element.css('overflow') == 'hidden'
            return

          delta = if _.isFunction(amount) then amount() else amount
          element.scrollTop(element.scrollTop() + delta)

      # Line scroll
      jwerty.key 'up',   scrollByFn(-lineScrollDelta)
      jwerty.key 'down', scrollByFn( lineScrollDelta)

      # Page scroll
      jwerty.key 'page-up',   scrollByFn(-> -element.height())
      jwerty.key 'page-down', scrollByFn(->  element.height())
  )
