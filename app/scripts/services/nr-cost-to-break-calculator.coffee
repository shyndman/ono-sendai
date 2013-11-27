class CostToBreakCalculator

  constructor: (@cardService)


angular.module('onoSendai')
  .service 'costToBreakCalculator', (cardService) ->
    new CostToBreakCalculator(args...)

