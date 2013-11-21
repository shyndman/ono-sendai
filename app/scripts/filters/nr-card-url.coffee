# Accepts a lower case type, and returns its plural
pluralizeType = (type) ->
  switch type
    when 'identity'
      'identities'
    when 'ice', 'hardware'
      type
    else
      "#{ type }s"

angular.module('deckBuilder')
  .filter 'cardUrl', ($log, idifyFilter) ->
    (card, urlType) ->
      switch urlType
        when 'type'
          "/cards/#{ card.side.toLowerCase() }/#{ pluralizeType(card.type.toLowerCase()) }"
        when 'set'
          "/cards/#{ card.side.toLowerCase() }?set=#{ idifyFilter(card.set) }"
        else
          $log.warn("cardUrl: Unknown urlType #{ urlType }")
