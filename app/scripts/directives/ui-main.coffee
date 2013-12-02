angular.module('onoSendai')
  .directive('main', ->
    lineScrollDelta = 40

    restrict: 'E'
    link: (scope, element, attrs) ->
      scrollBy = (amount) ->
        ->
          if element.css('overflow') == 'hidden'
            return

          delta = if _.isFunction(amount) then amount() else amount
          element.scrollTop(element.scrollTop() + delta)

      # Line scroll
      jwerty.key 'up',   scrollBy(-lineScrollDelta)
      jwerty.key 'down', scrollBy( lineScrollDelta)

      # Page scroll
      jwerty.key 'page-up',   scrollBy(-> -element.height())
      jwerty.key 'page-down', scrollBy(->  element.height())
  )
