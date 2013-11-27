class CostToBreakCalculator

  constructor: (@cardService)


angular.module('deckBuilder')
  .service 'costToBreakCalculator', (cardService) ->
    new CostToBreakCalculator(args...)

