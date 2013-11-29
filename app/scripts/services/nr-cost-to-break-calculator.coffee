class CostToBreakCalculator
  constructor: (@$log, $q, @cardService, @breakScripts) ->
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

  calculate: (card, iceAdjust) =>
    if !@isCardApplicable(card)
      @$log.error("#{ card.title } does not have a cost to break calculation, because it isn't ICE or a breaker")
      return

    _.logGroup "Cost to break for #{ card.title }",
      _.timed "Calculation time", =>
        if card.type == 'ICE'
          @_calculateForIce(card, iceAdjust)
        else if card.type == 'Program'
          @_calculateForIcebreaker(card, iceAdjust)

  _calculateForIce: (ice, iceAdjust) ->
    breakers = []

    # If the user has specified an ICE strength adjustment, apply it to a copy of the card
    if @_validIceAdjust(iceAdjust)
      ice = _.extend angular.copy(ice), strength: ice.strength + iceAdjust

    # Collect all potential opponent cards
    if ice.subtypesSet['sentry']
      breakers = breakers.concat @_killers.orderedCards

    if ice.subtypesSet['barrier']
      breakers = breakers.concat @_fracters.orderedCards

    if ice.subtypesSet['code-gate']
      breakers = breakers.concat @_decoders.orderedCards

    # [todo] How does Deus X fit in here

    breakers = breakers.concat @_ais.orderedCards

    {
      opponentType: 'Icebreakers'
      opponents: _.map _.sortBy(breakers, 'title'), (b) =>
        card: b
        interaction: @_calculateInteraction(ice, b)
    }

  _calculateForIcebreaker: (breaker, iceAdjust) ->
    ice = []

    if breaker.subtypesSet['killer']
      ice = ice.concat @_sentries.orderedCards

    if breaker.subtypesSet['fracter']
      ice = ice.concat @_barriers.orderedCards

    if breaker.subtypesSet['decoder']
      ice = ice.concat @_codeGates.orderedCards

    if breaker.subtypesSet['ai']
      ice = ice.concat @_allIce.orderedCards

    if breaker.breakcardsscript?
      ice = ice.concat @breakScripts[breaker.breakcardsscript](breaker, @_allIce.orderedCards)

    # If the user has specified an ICE strength adjustment, apply it to copies of the cards
    if @_validIceAdjust(iceAdjust)
      ice = _.map ice, (i) ->
        _.extend angular.copy(i), strength: i.strength + iceAdjust

    {
      opponentType: 'ICE'
      opponents: _.map _.sortBy(ice, 'title'), (i) =>
        card: i
        interaction: @_calculateInteraction(i, breaker)
    }

  _validIceAdjust: (val) ->
    _.isNumber(val) and val != 0

  _calculateInteraction: (ice, breaker) ->
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
      if @breakScripts[breaker.breakscript](interaction, breaker, strengthCost, breakCost, ice) == true
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

  _performQuery: (side, type, subtype) ->
    @cardService.query(
      side: side,
      activeGroup:
        name: type
      fieldFilters:
        subtype: subtype
    )

# Card-specific break scripts.
class BreakScripts

  atman: (interaction, breaker, strengthCost, breakCost, ice) ->
    if @_handleAntiAI(interaction, ice)
      return true # break complete

    interaction.breakerCondition = "= #{ ice.strength }"
    breaker.strength = ice.strength

  crypsis: (interaction, breaker, strengthCost, breakCost, ice) ->
    if @_handleAntiAI(interaction, ice)
      return true # break complete

  darwin: (interaction, breaker, strengthCost, breakCost, ice) ->
    if @_handleAntiAI(interaction, ice)
      return true # break complete

    interaction.breakerCondition = "≥ #{ ice.strength }"
    breaker.strength = ice.strength

  deusxCards: (breaker, allIce) ->
    _.filter(allIce, (i) -> i.subtypesSet.ap)

  wyrm: (interaction, breaker, strengthCost, breakCost, ice) ->
    if @_handleAntiAI(interaction, ice)
      return true # break complete

    interaction.credits += ice.strength
    false # continue break

  _handleAntiAI: (interaction, ice) ->
    if ice.id == 'swordsman'
      interaction.reason = 'AI icebreakers cannot be used against this ICE'
      true
    else
      false


angular.module('onoSendai')
  .service('costToBreakCalculator', ($log, $q, cardService, breakScripts) ->
    new CostToBreakCalculator(arguments...))
  .value('breakScripts', new BreakScripts())
