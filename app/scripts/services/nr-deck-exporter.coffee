# Exports decks into a variety of formats
class DeckExporter

  constructor: (@$log) ->

  export: (deck, format) ->
    switch format
      when 'markdown'
        exportMarkdown(deck)
      when 'octgn'
        exportOctgn(deck)
      else
        @$log.error("Unrecognized export format: #{ format }")

        """
        Reina Roja: Freedom Fighter
        Event (9)
        2 Account Siphon ••••• •••
        2 Deja Vu
        2 Emergency Shutdown ••••
        3 Sure Gamble
        Hardware (2)
        2 Deep Red
        Resource (15)
        1 Aesop's Pawnshop ••
        3 Armitage Codebusting
        3 Daily Casts
        1 Ice Carver
        3 Kati Jones
        2 Wyldside
        2 Xanadu
        Icebreaker (6)
        3 Crypsis
        3 Knight
        Program (13)
        3 Bishop
        1 Gorman Drip v1 •
        1 Medium
        1 Nerve Agent
        3 Parasite
        3 Rook
        1 Scheherazade
        """

  exportMarkdown: (deck) ->
    str = "**#{ deck.identity().title }**\n"

    for group in deck.cardQuantityGroups(identity: false)
      str += "**#{ group.title }** **#{ group.length }**\n"
      for { card, quantity } in group.cardQuantities
        str += "#{ quantity } #{ card.title }\n" # [todo] Link to card, influence

    if deck.description?
      str += """
             *****
             #{ deck.description }
             """
    str

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

    for group in deck.cardQuantityGroups(identity: false)
      for { card, quantity } in group.cardQuantities
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
