angular.module('onoSendai')
  .directive('costToBreakCalculator', (costToBreakCalculator) ->
    templateUrl: '/views/directives/nr-cost-to-break-calculator.html'
    restrict: 'E'
    scope: {
      card: '='
    }
    link: (scope, element, attrs) ->
      lastCard = null

      # Sets and filters the opponents and calculates stats
      invalidate = (costToBreakInfo = scope.costToBreakInfo, filter = scope.opponentFilter) ->
        if !costToBreakInfo?
          return

        scope.costToBreakInfo = costToBreakInfo

        # Apply filter
        scope.opponents = _.filter costToBreakInfo.opponents, (opponent) ->
          _.str.include(opponent.card.title.toLowerCase(), filter) or
          _.str.include(opponent.card.faction.toLowerCase(), filter)

        # Stats!
        credits = _.filter(_.map(scope.opponents, (opponent) -> opponent.interaction.creditsSpent), (credits) -> credits?)
        scope.averageCredits = _.average(credits)
        scope.medianCredits = _.median(credits)
        scope.brokenCount = _.filter(scope.opponents, (opponent) -> opponent.interaction.broken).length
        scope.unbrokenCount = scope.opponents.length - scope.brokenCount

      scope.$watch 'opponentFilter', filterChanged = (filter) ->
        invalidate(null, (filter ? '').trim().toLowerCase())

      scope.$watch 'card', cardChanged = (card) ->
        return if !card?

        # Clear the filter if we're switch sides, because it wouldn't make sense in the other context
        if lastCard?.side != card.side
          scope.opponentFilter = ''

        # Calculate cost to break on ICE or breakers
        if costToBreakCalculator.isCardApplicable(card)
          invalidate(costToBreakCalculator.calculate(card), null)

        lastCard = card
  )
