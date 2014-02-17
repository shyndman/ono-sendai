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

  # Weaves two or more arrays together.
  #
  # ie. weave([a, a, a], [b, b, b]) returns [a, b, a, b, a, b]
  weave: (args...) ->
    unless _.any(args)
      return []

    _.compact(_.flatten(_.zip(args...), true))

  # Concatenates the provided arrays together, and returns the result.
  concat: (arrs...) ->
    _.reduce(_.compact(arrs), ((a, b) -> a.concat(b)), [])

  # String.replace, but chainable.
  replace: (str, args...) ->
    str.replace(args...)

  # Generates a URL friendly ID string from the provided string
  idify: (str) ->
    _.stripDiacritics(_.dasherize(str.toLowerCase().replace(/["|'|:|*|\.]/g, '')))

  # Returns an object containing only properties that pass a truth test. The
  # iterator is called with key and value arguments.
  filterObj: (obj, iterator) ->
    _.object([key, val] for key, val of obj when iterator(key, val))

  # Returns a number indicating whether a string comes before or after
  # or is the same as another string in sort order. Handles undefined strings.
  stringCompare: (a, b) ->
    if a? and !b?
      -1
    else if !a? and b?
      1
    else if !a? and !b?
      0
    else
      a.localeCompare(b)

  # Returns a number indicating whether a number comes before or after
  # or is the same as another number in sort order. Handles undefined numbers.
  numericCompare: (a, b) ->
    if a? and !b?
      -1
    else if !a? and b?
      1
    else if !a? and !b?
      0
    else
      a - b

  # Nada, nothing, beans, bupkis
  noop: -> ;


# ~*~*~* STATISTICS

_.mixin
  sum: (arr) ->
    _.reduce(arr, ((sum, i) -> sum + i), 0)

  average: (arr) ->
    if _.isEmpty(arr)
      null
    else
      _.sum(arr) / arr.length

  median: (arr) ->
    if _.isEmpty(arr)
      null
    else
      sorted = arr.slice().sort((a, b) -> a - b)
      if sorted.length % 2 == 0
        (sorted[arr.length / 2 - 1] + sorted[arr.length / 2]) / 2
      else
        sorted[Math.floor(arr.length / 2)]


# ~*~*~* DEBUGGING UTILITIES

# Returns a function that returns a function to performs one of the debug functions.
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
      console.time?(name)
      fn()
    finally
      console.timeEnd?(name)

  # Creates a new log group (console.group) around the specified function.
  logGroup: (name, fnOrCollapsed, fn) ->
    try
      if _.isBoolean(fnOrCollapsed)
        collapsed = fnOrCollapsed
      else
        collapsed = false
        fn = fnOrCollapsed

      if collapsed
        console.groupCollapsed?(name)
      else
        console.group?(name)
      fn()
    finally
      console.groupEnd?(name)

  # Returns a function that will be profiled whenever invoked
  profiled: wrap('profile')

  # Returns a function that will be timed whenever invoked
  timed: wrap('time')

  # Returns a function that will be wrapped in a log group whenever invoked.
  logGrouped: wrap('logGroup')


# ~*~*~* DIACRITICS

accentsFrom  = 'ąàáäâãåæăćęèéëêìíïîłńòóöôõōøśșțùúüûñçżź'
accentsTo    = 'aaaaaaaaaceeeeeiiiilnooooooosstuuuunczz'
accentsRegex = ///[#{accentsFrom}]///g
accentsMapping = _.object(_.zip(_.str.chars(accentsFrom), _.str.chars(accentsTo)))

_.mixin
  stripDiacritics: (str) ->
    str = String(str).toLowerCase().replace accentsRegex, (c) -> accentsMapping[c]
