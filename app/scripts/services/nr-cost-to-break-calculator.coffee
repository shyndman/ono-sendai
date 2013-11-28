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
        'fracter':   @_fracters
        'decoder':   @_decoders
        'ai':        @_ais
      }) => @$log.debug('Cost to Break queries complete'))

  isCardApplicable: (card) =>
    card.type == 'ICE' or 'icebreaker' of card.subtypesSet

  calculate: (card) =>
    if !@isCardApplicable(card)
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

    {
      opponentType: 'Icebreakers'
      opponents: _.map _.sortBy(breakers, 'title'), (b) =>
        card: b
        interaction: @_calculateInteraction(ice, b)
    }

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

    {
      opponentType: 'ICE'
      opponents: _.map _.sortBy(ice, 'title'), (i) =>
        card: i
        interaction: @_calculateInteraction(i, breaker)
    }

  _calculateInteraction: (ice, breaker) ->
    strengthCost =
      if _.isNumber(breaker.strengthcost)
        { credits: breaker.strengthcost, strength: 1 }
      else
        breaker.strengthcost
    breakCost = breaker.breakcost

    # Simulate the ICE breaking
    creditsSpent = 0
    strengthLeft = ice.strength
    strengthLeft -= breaker.strength

    if strengthLeft > 0 and !strengthCost?
      return broken: false, reason: 'Fixed breaker, strength too low'

    while strengthLeft > 0
      creditsSpent += strengthCost.credits
      strengthLeft -= strengthCost.strength

    if breakCost.subroutines == 'all'
      creditsSpent += breakCost.credits
    else
      creditsSpent += Math.ceil(ice.subroutinecount / breakCost.subroutines) * breakCost.credits

    {
      broken: true
      creditsSpent: creditsSpent
      steps: []
    }

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

