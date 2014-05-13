# Exports decks into a variety of formats
class DeckExporter

  constructor: (@$log) ->

  export: (deck, format) ->
    switch format
      when 'octgn'
        exportOctgn(deck)
      else
        @$log.error("Unrecognized export format: #{ format }")

  exportOctgn: (deck) ->
    identity = deck.identity()

    str =
      """
      <?xml version="1.0" encoding="utf-8" standalone="yes"?>
      <deck game="0f38e453-26df-4c04-9d67-6d43de939c77">
        <section name="Identity">
          <card qty="1" id="#{ identity.octgnid }">#{ identity.title }</card>
        </section>
        <section name="R&amp;D / Stack">
      """

    for { card, quantity } in deck.cardQuantities(noIdentity: true)
      str +=
        """    <card qty="#{ quantity }" id="#{ card.octgnid }">#{ card.title }</card>\n"""

    str +=
      """
        </section>
        <notes><![CDATA[#{ deck.title }\n\n#{ deck.notes ? '' }!]]></notes>
      </deck>
      """

    str




angular.module('onoSendai')
  .service 'deckExporter', ($log) ->
    new DeckExporter(arguments...)
