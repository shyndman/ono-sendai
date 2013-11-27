# Accepts a lower case type, and returns its plural
pluralizeType = (type) ->
  switch type
    when 'identity'
      'identities'
    when 'ice', 'hardware'
      type
    else
      "#{ type }s"

angular.module('onoSendai')
  .filter 'cardUrl', ($log, $location) ->
    urlPrefix =
      if $location.$$html5
        ''
      else
        '#!'

    # arg - optional argument for some urlTypes
    (card, urlType, arg) ->
      if !card?
        return ''

      side = card.side.toLowerCase()

      switch urlType
        when 'type'
          "#{ urlPrefix }/cards/#{ side }/#{ pluralizeType(card.type.toLowerCase()) }"
        when 'set'
          "#{ urlPrefix }/cards/#{ side }?setname=#{ _.idify(card.setname) }"
        when 'subtype'
          "#{ urlPrefix }/cards/#{ side }?subtype=#{ _.idify(arg) }"
        else
          $log.warn("cardUrl: Unknown urlType #{ urlType }")
          ''
