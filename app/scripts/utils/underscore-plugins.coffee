_.mixin
  multiSort: (sortFns...) ->
    (a, b) ->
      for fn in sortFns
        return order if (order = fn(a, b)) isnt 0
      order


accentsFrom  = "ąàáäâãåæăćęèéëêìíïîłńòóöôõøśșțùúüûñçżź"
accentsTo    = "aaaaaaaaaceeeeeiiiilnoooooosstuuuunczz"
accentsRegex = ///[#{accentsFrom}]///g
accentsMapping = _.object(_.zip(accentsFrom.split(''), accentsTo.split('')))

_.mixin
  stripDiacritics: (str) ->
    str = String(str).toLowerCase().replace accentsRegex, (c) -> accentsMapping[c]
