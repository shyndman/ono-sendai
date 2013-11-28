class CostToBreakCalculator
  constructor: (@$log, $q, @cardService) ->
    $q.all(
        'sentry':    @_performQuery('Corp', 'ice', 'sentry')
        'barrier':   @_performQuery('Corp', 'ice', 'barrier')
        'code-gate': @_performQuery('Corp', 'ice', 'code-gate')
        'allIce':    @_performQuery('Corp', 'ice')
        'killer':    @_performQuery('Runner', 'program', 'killer')
        'fracter':   @_performQuery('Runner', 'program', 'fracter')
        'decoder':   @_performQuery('Runner', 'program', 'decoder')
        'ai':        @_performQuery('Runner', 'program', 'ai')
      ).then(({
        'sentry':    @_sentries
        'barrier':   @_barriers
        'code-gate': @_codeGates
        'allIce':    @_allIce
        'killer':    @_killers
        'decoder':   @_decoders
        'ai':        @_ais
      }) => @$log.debug('Cost to Break queries complete'))

  canCalculate: (card) =>
    card.type == 'ICE' or 'icebreaker' of card.subtypesSet

  calculate: (card) ->
    if !@canCalculate(card)
      @$log.error("#{ card.title } does not have a cost to break calculation, because it isn't ICE or a breaker")
      return

    if card.type == 'ICE'
      @_calculateForIce(card)
    else if card.type == 'Program'
      @_calculateForIcebreaker(card)

  _calculateForIce: (ice) ->
    breakers = []

    if ice.subtypesSet['sentry']
      breakers = breakers.concat @_killers.orderedCards

    if ice.subtypesSet['barrier']
      breakers = breakers.concat @_fracters.orderedCards

    if ice.subtypesSet['code-gate']
      breakers = breakers.concat @_decoders.orderedCards

    breakers = breakers.concat @_ais.orderedCards

    _.map _.sortBy(breakers, 'title'), (b) => @_calculateInteraction(ice, b)

  _calculateForIcebreaker: (breaker) ->
    ice = []

    if breaker.subtypesSet['killer']
      ice = ice.concat @_sentries.orderedCards

    if breaker.subtypesSet['fracter']
      ice = ice.concat @_barriers.orderedCards

    if breaker.subtypesSet['decoder']
      ice = ice.concat @_codeGates.orderedCards

    if breaker.subtypesSet['ai']
      ice = ice.concat @_allIce.orderedCards

    _.map _.sortBy(ice, 'title'), (i) => @_calculateInteraction(i, breaker)

  _calculateInteraction: (ice, breaker) ->
    console.warn ice.subtypes, breaker.subtypes

  _performQuery: (side, type, subtype) ->
    @cardService.query(
      side: side,
      activeGroup:
        name: type
      fieldFilters:
        subtype: subtype
    )


angular.module('onoSendai')
  .service 'costToBreakCalculator', ($log, $q, cardService) ->
    new CostToBreakCalculator(arguments...)

