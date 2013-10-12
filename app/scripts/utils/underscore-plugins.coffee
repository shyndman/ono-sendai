_.mixin
  multiGroup: ()

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


accentsFrom  = "ąàáäâãåæăćęèéëêìíïîłńòóöôõōøśșțùúüûñçżź"
accentsTo    = "aaaaaaaaaceeeeeiiiilnooooooosstuuuunczz"
accentsRegex = ///[#{accentsFrom}]///g
accentsMapping = _.object(_.zip(_.str.chars(accentsFrom), _.str.chars(accentsTo)))

_.mixin
  stripDiacritics: (str) ->
    str = String(str).toLowerCase().replace accentsRegex, (c) -> accentsMapping[c]
