angular.module('onoSendai')
  .directive('costToBreakCalculator', (costToBreakCalculator) ->
    templateUrl: '/views/directives/nr-cost-to-break-calculator.html'
    restrict: 'E'
    scope: {
      card: '='
    }
    link: (scope, element, attrs) ->
      lastCard = null
      scope.$watch 'card', cardChanged = (card) ->
        return if !card?

        # Calculate cost to break on ICE or breakers
        if costToBreakCalculator.isCardApplicable(card)
          scope.costToBreakInfo = costToBreakCalculator.calculate(card)

        if lastCard?.side != card.side
          scope.opponentFilter = ''

        lastCard = card
  )
