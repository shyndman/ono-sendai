_.mixin
  # Sorts an array by a sequence of comparison functions (of the type generally provided to
  # Array#sort). If the first function in the list of functions reports equality between two
  # elements will then use the next function in the sequence, then the next, and so on.
  multiSort: (arr, sortFns...) ->
    copy = arr.slice()
    copy.sort (a, b) ->
      for fn in sortFns
        if (order = fn(a, b)) != 0
          return order
      order

  # Returns an array with two internal arrays built from taking an original array
  # and spliting it at an index.
  splitAt: (array, index) ->
    return [ _.take(array, index), _.drop(array, index) ]

  # Weaves two or more arrays together
  weave: (args...) ->
    unless _.some(args)
      return []

    _.compact(_.flatten(_.zip(args...), true))

  # Concatenates the provided the array, and returns the result.
  concat: (arrs...) ->
    arr = []
    for a in arrs when a?
      arr = arr.concat(a)
    arr

  # String.replace, but chainable.
  replace: (str, args...) ->
    str.replace(args...)

  # Generates a URL friendly ID string from the provided string
  idify: (str) ->
    _.stripDiacritics(_.dasherize(str.toLowerCase().replace(/["|'|:|*]/g, '')))

  # Returns an object containing only properties that pass a truth test. The
  # iterator is called with key and value arguments.
  filterObj: (obj, iterator) ->
    _.object([key, val] for key, val of obj when iterator(key, val))

  # Nada, nothing, beans, bupkis
  noop: ->


# ~*~*~* DEBUGGING UTILITIES

wrap = (methodName) ->
  (name, fn) ->
    (args...) ->
      thisArg = @
      _[methodName](name, _.bind(fn, thisArg, args...))

_.mixin
  # Profiles the provided function.
  profile: (nameOrFn, fn) ->
    if !fn
      fn = nameOrFn
      name = ''
    else
      name = nameOrFn

    try
      console.profile(name)
      fn()
    finally
      console.profileEnd(name)

  # Times the provided function.
  time: (name, fn) ->
    try
      console.time(name)
      fn()
    finally
      console.timeEnd(name)

  # Creates a new log group (console.group) around the specified function.
  logGroup: (name, fn) ->
    try
      console.group(name)
      fn()
    finally
      console.groupEnd(name)

  # Returns a function that will be profiled whenever invoked
  profiled: wrap('profile')

  # Returns a function that will be timed whenever invoked
  timed: wrap('time')

  # Returns a function that will be wrapped in a log group whenever invoked.
  logGrouped: wrap('logGroup')


  # ~*~*~* DIACRITICS

accentsFrom  = "ąàáäâãåæăćęèéëêìíïîłńòóöôõōøśșțùúüûñçżź"
accentsTo    = "aaaaaaaaaceeeeeiiiilnooooooosstuuuunczz"
accentsRegex = ///[#{accentsFrom}]///g
accentsMapping = _.object(_.zip(_.str.chars(accentsFrom), _.str.chars(accentsTo)))

_.mixin
  stripDiacritics: (str) ->
    str = String(str).toLowerCase().replace accentsRegex, (c) -> accentsMapping[c]
