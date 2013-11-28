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

        filter = filter.trim()
        scope.costToBreakInfo = costToBreakInfo
        scope.opponents = _.filter costToBreakInfo.opponents, (opponent) ->
          _.str.include(opponent.card.title.toLowerCase(), filter) or
          _.str.include(opponent.card.faction.toLowerCase(), filter)


      scope.$watch 'opponentFilter', filterChanged = (filter) ->
        invalidate(null, filter ? '')

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
