_.mixin
  multiSort: (sortFns...) ->
    (a, b) ->
      for fn in sortFns
        return order if (order = fn(a, b)) isnt 0
      order
