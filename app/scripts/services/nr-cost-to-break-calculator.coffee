class CostToBreakCalculator
  constructor: (@$log, $q, @cardService, @breakScripts) ->
    @$log.debug 'Performing cost-to-break startup queries'

    $q.all(
        'sentry':         @_performQuery('Corp', 'ice', 'sentry')
        'barrier':        @_performQuery('Corp', 'ice', 'barrier')
        'code-gate':      @_performQuery('Corp', 'ice', 'code-gate')
        'ap':             @_performQuery('Corp', 'ice', 'ap')
        'destroyer':      @_performQuery('Corp', 'ice', 'destroyer')
        'tracer':         @_performQuery('Corp', 'ice', 'tracer')
        'allIce':         @_performQuery('Corp', 'ice')
        'killer':         @_performQuery('Runner', 'program', 'killer')
        'fracter':        @_performQuery('Runner', 'program', 'fracter')
        'decoder':        @_performQuery('Runner', 'program', 'decoder')
        'anti-ap':        @_performQuery('Runner', 'program', 'anti-ap')
        'anti-destroyer': @_performQuery('Runner', 'program', 'anti-destroyer')
        'anti-tracer':    @_performQuery('Runner', 'program', 'anti-tracer')
        'ai':             @_performQuery('Runner', 'program', 'ai')
      ).then(({
        'sentry':         @_sentries
        'barrier':        @_barriers
        'code-gate':      @_codeGates
        'ap':             @_aps
        'destroyer':      @_destroyers
        'tracer':         @_tracers
        'allIce':         @_allIce
        'killer':         @_killers
        'fracter':        @_fracters
        'decoder':        @_decoders
        'anti-ap':        @_antiAps
        'anti-destroyer': @_antiDestroyers
        'anti-tracer':    @_antiTracers
        'ai':             @_ais
      }) => @$log.debug('Cost to Break queries complete'))

  isCardApplicable: (card) =>
    card.type == 'ICE' or 'icebreaker' of card.subtypesSet

  calculate: (card, iceAdjust, options) =>
    if !@isCardApplicable(card)
      @$log.warn("#{ card.title } does not have a cost to break calculation, because it isn't ICE or a breaker")
      return

    _.logGroup "Cost to break for #{ card.title }",
      _.timed 'Calculation time', =>
        if card.type == 'ICE'
          @_calculateForIce(card, iceAdjust, options)
        else if card.type == 'Program'
          @_calculateForIcebreaker(card, iceAdjust, options)

  _calculateForIce: (ice, iceAdjust, options) ->
    breakers = []

    # If the user has specified an ICE strength adjustment, apply it to a copy of the card
    if @_validIceAdjust(iceAdjust)
      ice = _.extend angular.copy(ice), originalstrength: ice.strength, strength: ice.strength + iceAdjust

    # Collect all potential opponent cards
    if ice.subtypesSet['sentry'] or options.tinkering
      breakers = breakers.concat @_killers.orderedCards

    if ice.subtypesSet['barrier'] or options.tinkering
      breakers = breakers.concat @_fracters.orderedCards

    if ice.subtypesSet['code-gate'] or options.tinkering
      breakers = breakers.concat @_decoders.orderedCards

    if ice.subtypesSet['ap']
      breakers = breakers.concat @_antiAps.orderedCards

    if ice.subtypesSet['destroyer']
      breakers = breakers.concat @_antiDestroyers.orderedCards

    if ice.subtypesSet['tracer']
      breakers = breakers.concat @_antiTracers.orderedCards


    # [todo] How do Deus X / Sharpshooter fit in here

    breakers = breakers.concat @_ais.orderedCards

    {
      opponentType: 'Icebreakers'
      opponents: _.map _.sortBy(breakers, 'title'), (b) =>
        card: b
        interaction: @_calculateInteraction(ice, b, options)
    }

  _calculateForIcebreaker: (breaker, iceAdjust, options) ->
    ice = []

    if breaker.subtypesSet['killer']
      ice = ice.concat @_sentries.orderedCards

    if breaker.subtypesSet['fracter']
      ice = ice.concat @_barriers.orderedCards

    if breaker.subtypesSet['decoder']
      ice = ice.concat @_codeGates.orderedCards

    if breaker.subtypesSet['anti-ap']
      ice = ice.concat @_aps.orderedCards

    if breaker.subtypesSet['anti-destroyer']
      ice = ice.concat @_destroyers.orderedCards

    if breaker.subtypesSet['anti-tracer']
      ice = ice.concat @_tracers.orderedCards

    if breaker.subtypesSet['ai'] or options.tinkering
      ice = ice.concat @_allIce.orderedCards

    if breaker.breakcardsscript?
      ice = ice.concat @breakScripts[breaker.breakcardsscript](breaker, @_allIce.orderedCards)

    # If the user has specified an ICE strength adjustment, apply it to copies of the cards
    if @_validIceAdjust(iceAdjust)
      ice = _.map ice, (i) ->
        _.extend angular.copy(i), originalstrength: i.strength, strength: i.strength + iceAdjust

    {
      opponentType: 'ICE'
      opponents: _.map _.sortBy(ice, 'title'), (i) =>
        card: i
        interaction: @_calculateInteraction(i, breaker, options)
    }

  _calculateInteraction: (ice, breaker, options) ->
    interaction = credits: 0, broken: false, steps: []
    strengthCost =
      if _.isNumber(breaker.strengthcost)
        { credits: breaker.strengthcost, strength: 1 }
      else
        breaker.strengthcost
    breakCost = breaker.breakcost

    # If we have a custom break script, invoke it
    if breaker.breakscript?
      # Make copies of the cards, so that the break script can mutate their attributes
      ice = angular.copy(ice)
      breaker = angular.copy(breaker)

      # Check to see whether the custom script can handle the entire break...
      breakScript = @breakScripts[breaker.breakscript]
      if breakScript(interaction, breaker, strengthCost, breakCost, ice, options) == true
        return interaction
      # ...otherwise continue with the break (with the interaction potentially modified)

    # Simulate the ICE breaking
    creditsSpent = interaction.credits
    strengthLeft = ice.strength
    strengthLeft -= breaker.strength

    if strengthLeft > 0 and !strengthCost?
      return _.extend(interaction, reason: 'Fixed breaker, strength too low')

    while strengthLeft > 0
      creditsSpent += strengthCost.credits
      strengthLeft -= strengthCost.strength

    if breakCost.subroutines == 'all'
      creditsSpent += breakCost.credits
    else
      creditsSpent += Math.ceil(ice.subroutinecount / breakCost.subroutines) * breakCost.credits

    _.extend(interaction,
      broken: true
      creditsSpent: creditsSpent)

  _validIceAdjust: (val) ->
    _.isNumber(val) and val != 0

  _performQuery: (side, type, subtype) ->
    @cardService.query(
      side: side,
      activeGroup: type
      fieldFilters:
        subtype: subtype
    )


# Card-specific break scripts.
class BreakScripts

  # If breakerStrength is specified, Atman will only break ICE of the same strength
  atman: (interaction, breaker, strengthCost, breakCost, ice, { breakerStrength } = {}) =>
    if @_handleAntiAI(interaction, ice)
      return true # break complete

    if ice.strength < 0
      interaction.reason = 'ICE strength too low'
      return true # Atman cannot be set to < 0

    if breakerStrength?
      if ice.strength != breakerStrength
        interaction.reason = 'Strengths are not equal'
        return true
      else
        breaker.strength = breakerStrength
        return false

    interaction.breakerCondition = "= #{ ice.strength }"
    breaker.strength = ice.strength

  genericAI: (interaction, breaker, strengthCost, breakCost, ice) =>
    if @_handleAntiAI(interaction, ice)
          return true # break complete

  darwin: (interaction, breaker, strengthCost, breakCost, ice, { breakerStrength } = {}) =>
    if @_handleAntiAI(interaction, ice)
      return true # break complete

    if breakerStrength?
      breaker.strength = breakerStrength
    else
      breaker.strength = Math.max(ice.strength, 0)
      interaction.breakerCondition = "≥ #{ breaker.strength }"

  wyrm: (interaction, breaker, strengthCost, breakCost, ice) =>
    if @_handleAntiAI(interaction, ice)
      return true # break complete

    interaction.credits += ice.strength
    false # continue break

  _handleAntiAI: (interaction, ice) =>
    if ice.id == 'swordsman'
      interaction.reason = 'AI icebreakers cannot be used against this ICE'
      true
    else
      false


angular.module('onoSendai')
  .service('costToBreakCalculator', ($log, $q, cardService, breakScripts) ->
    new CostToBreakCalculator(arguments...))
  .value('breakScripts', new BreakScripts())
