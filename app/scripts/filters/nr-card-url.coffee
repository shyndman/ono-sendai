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
    # [todo] Extract the patterns to an angular constant
    serveLocalImages = $location.host().match(/localhost/)? # or $location.host().match(/stage\.onosendaicorp\.com/)

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
        when 'card'
          "#{ urlPrefix }/cards/#{ side }/card/#{ card.id }"
        when 'type'
          "#{ urlPrefix }/cards/#{ side }/#{ pluralizeType(card.type.toLowerCase()) }"
        when 'set'
          "#{ urlPrefix }/cards/#{ side }?setname=#{ _.idify(card.setname) }&group=setname"
        when 'subtype'
          "#{ urlPrefix }/cards/#{ side }?subtype=#{ _.idify(arg) }"
        when 'image'
          if serveLocalImages
            card.imagesrc
          else
            # [todo] Extract this URL to an angular constant?
            "http://d3t3ih6ri0e76u.cloudfront.net/#{ card.imagesrc }"
        else
          $log.warn("cardUrl: Unknown urlType #{ urlType }")
          ''
