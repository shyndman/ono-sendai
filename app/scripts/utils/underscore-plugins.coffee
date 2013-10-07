_.mixin
  multiSort: (sortFns...) ->
    (a, b) ->
      for fn in sortFns
        return order if (order = fn(a, b)) isnt 0
      order

  concat: ([arrays...]) ->
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
