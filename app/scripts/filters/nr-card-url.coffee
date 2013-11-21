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
  .filter 'cardUrl', ($log) ->

    # arg - optional argument for some urlTypes
    (card, urlType, arg) ->
      if !card?
        return ''

      side = card.side.toLowerCase()

      switch urlType
        when 'type'
          "/cards/#{ side }/#{ pluralizeType(card.type.toLowerCase()) }"
        when 'set'
          "/cards/#{ side }?set=#{ _.idify(card.setname) }"
        when 'subtype'
          "/cards/#{ side }?subtype=#{ _.idify(arg) }"
        else
          $log.warn("cardUrl: Unknown urlType #{ urlType }")
          ''
