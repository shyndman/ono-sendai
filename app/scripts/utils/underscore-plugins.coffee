_.mixin
  # Sorts an array by a sequence of comparison functions (of the type generally provided to
  # Array#sort. If the first function in the list of functions reports equality between two
  # elements will then use the next function in the sequence, then the next, and so on.
  multiSort: (arr, sortFns...) ->
    copy = arr.slice()
    copy.sort (a, b) ->
      for fn in sortFns
        return order if (order = fn(a, b)) isnt 0
      order

  # Concatenates the provided the array, and returns the result.
  concat: (arrays...) ->
    arr = []
    for a in arrays
      continue unless a?
      arr = arr.concat(a)
    arr

  # Nada, nothing, beans, bupkis
  noop: ->


  # *~*~*~*~ DEBUG HELPERS

  # Profiles immediately
  profile: (name, fn) ->
    if !fn
      fn = name
      name = ''
    console.profile(name)
    ret = fn()
    console.profileEnd(name)
    ret

  # Returns a function that will be profiled whenever invoked
  # name (optional)
  profiled: (name, fn) ->
    (args...) -> _.profile(name, _.partial(fn, args...))

  time: (name, fn) ->
    console.time(name)
    ret = fn()
    console.timeEnd(name)
    ret

  timed: (name, fn) ->
    (args...) -> _.time(name, _.partial(fn, args...))

accentsFrom  = "ąàáäâãåæăćęèéëêìíïîłńòóöôõōøśșțùúüûñçżź"
accentsTo    = "aaaaaaaaaceeeeeiiiilnooooooosstuuuunczz"
accentsRegex = ///[#{accentsFrom}]///g
accentsMapping = _.object(_.zip(_.str.chars(accentsFrom), _.str.chars(accentsTo)))

_.mixin
  stripDiacritics: (str) ->
    str = String(str).toLowerCase().replace accentsRegex, (c) -> accentsMapping[c]
