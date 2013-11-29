angular.module('onoSendai')
  .directive('costToBreakCalculator', ($timeout, costToBreakCalculator) ->
    templateUrl: '/views/directives/nr-cost-to-break-calculator.html'
    restrict: 'E'
    scope: {
      card: '='
    }
    controller: ($scope, $attrs) ->
      lastCard = null

      # Sets and filters the opponents and calculates stats
      invalidate = ->
        costToBreakInfo = $scope.costToBreakInfo
        filter = ($scope.opponentFilter?.trim().toLowerCase() ? '')
        iceAdjust = $scope.iceAdjust

        if !costToBreakInfo?
          return

        # Apply filter
        $scope.opponents = _.filter costToBreakInfo.opponents, (opponent) ->
          _.str.include(opponent.card.title.toLowerCase(), filter) or
          _.str.include(opponent.card.faction.toLowerCase(), filter)

        # Stats!
        credits = _.filter(_.map($scope.opponents, (opponent) -> opponent.interaction.creditsSpent), (credits) -> credits?)
        $scope.averageCredits = _.average(credits)
        $scope.medianCredits = _.median(credits)
        $scope.brokenCount = _.filter($scope.opponents, (opponent) -> opponent.interaction.broken).length
        $scope.unbrokenCount = $scope.opponents.length - $scope.brokenCount

      $scope.$watch 'opponentFilter', filterChanged = (filter, oldFilter) ->
        if filter == oldFilter
          return

        invalidate()

      $scope.$watch 'iceAdjust', iceAdjustChanged = (iceAdjust, oldIceAdjust) ->
        if iceAdjust == oldIceAdjust
          return

        $scope.costToBreakInfo =
          costToBreakCalculator.calculate($scope.card, $scope.iceAdjust, breakerStrength: $scope.breakerStrength)
        invalidate()

      $scope.$watch 'breakerStrength', breakerStrengthChanged = (breakerStrength, oldBreakerStrength) ->
        if breakerStrength == oldBreakerStrength
          return

        $scope.costToBreakInfo =
          costToBreakCalculator.calculate($scope.card, $scope.iceAdjust, breakerStrength: breakerStrength)
        invalidate()

      $scope.$watch 'card', cardChanged = (card) ->
        if !card?
          return

        # Clear the filter if we're switch sides, because it wouldn't make sense in the other context
        if lastCard?.side != card.side
          $scope.opponentFilter = null
          $scope.iceAdjust = null

        $scope.breakerStrength = null

        # Calculate cost to break on ICE or breakers
        if costToBreakCalculator.isCardApplicable(card)
          $scope.costToBreakInfo =
            costToBreakCalculator.calculate(card, $scope.iceAdjust, breakerStrength: $scope.breakerStrength)
          invalidate()

        lastCard = card

    link: (scope, element, attrs) ->
      opponentsList = element.find('.opponents')

      # Scroll to the top of the list when the card changes
      scope.$watch 'card', ->
        $timeout -> opponentsList[0].scrollTop = 0
  )
