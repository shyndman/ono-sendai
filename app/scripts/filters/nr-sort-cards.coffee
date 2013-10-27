'use strict';

angular.module('deckBuilder')
  .filter 'sortCards', ($log) ->
    cachedFilterMap = null
    cachedOutput = null

    (input, filterMap) ->
      return [] if !filterMap?
      return cachedOutput if cachedFilterMap is filterMap

      _.time 'Sorting card elements', ->
        cachedFilterMap = filterMap
        cachedOutput = _.sortBy(input, (card) ->
          if filterMap[card.id]
            filterMap[card.id].ordinal
          else
            10000000)


