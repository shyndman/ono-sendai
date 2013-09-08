_.mixin
  multiSorter: (sort_fns...) ->
    (a, b) ->
      for fn in sort_fns
        return order if (order = fn(a, b)) isnt 0
      order
