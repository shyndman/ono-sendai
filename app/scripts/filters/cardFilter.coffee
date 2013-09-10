'use strict';

angular.module('deckBuilder')
  .filter 'cardFilter', (cardService) ->
    (cards, side, searchText) ->
      unless cards?
        return cards

      if searchText? and searchText.length
        cards = cardService.search(searchText)
      cards = (card for card in cards when card.side is side)

      return cards

      # groups = _.pairs(_.groupBy(cards, (card) -> "#{ card.side }-#{ card.faction }")).sort((a, b) -> a[0].localeCompare(b[0]))

      # console.log groups

      # groups

      # groups = _.groupBy(cards, (card) -> "#{ card.side }-#{ card.faction }")
      # groups
