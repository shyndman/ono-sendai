angular.module('onoSendai')
  .controller('CostToBreakCtrl', ($scope, $attrs, costToBreakCalculator) ->
      lastCard = null

      # Sets and filters the opponents and calculates stats
      invalidate = ->
        costToBreakInfo = $scope.costToBreakInfo
        filter = ($scope.opponentFilter?.trim().toLowerCase() ? '')
        iceAdjust = $scope.iceAdjust

        if !costToBreakInfo?
          return

        # Apply filters
        $scope.opponents = _.filter costToBreakInfo.opponents, (opponent) ->
          (
            _.str.include(_.stripDiacritics(opponent.card.title.toLowerCase()), filter) or
            _.str.include(opponent.card.faction.toLowerCase(), filter)
          ) and
          (
            !$scope.maxIceStrength? or
            (opponent.card.originalstrength ? opponent.card.strength) <= $scope.maxIceStrength
          )

        # Stats!
        credits = _.filter(_.map($scope.opponents, (opponent) -> opponent.interaction.creditsSpent), (credits) -> credits?)
        $scope.averageCredits = _.average(credits)
        $scope.medianCredits = _.median(credits)
        $scope.brokenCount = _.filter($scope.opponents, (opponent) -> opponent.interaction.broken).length
        $scope.unbrokenCount = $scope.opponents.length - $scope.brokenCount

      recalcCostToBreak = ->
        $scope.costToBreakInfo =
          costToBreakCalculator.calculate($scope.card, $scope.iceAdjust, breakerStrength: $scope.breakerStrength)


      # ~-~-~- MODEL WATCHES

      displayValueChanged = (newVal, oldVal) ->
        if newVal != oldVal
          invalidate()

      $scope.$watch 'opponentFilter', displayValueChanged
      $scope.$watch 'maxIceStrength', displayValueChanged

      inputValueChanged = (newVal, oldVal) ->
        if newVal != oldVal
          recalcCostToBreak()
          invalidate()

      $scope.$watch 'iceAdjust', inputValueChanged
      $scope.$watch 'breakerStrength', inputValueChanged

      $scope.$watch 'card', cardChanged = (card) ->
        if !card?
          return

        # Clear the filter if we're switch sides, because it wouldn't make sense in the other context
        if lastCard?.side != card.side
          $scope.opponentFilter = null
          $scope.iceAdjust = null
          $scope.maxIceStrength = null

        $scope.breakerStrength = null

        # Calculate cost to break on ICE or breakers
        if costToBreakCalculator.isCardApplicable(card)
          recalcCostToBreak()
          invalidate()

        lastCard = card
  )
  .directive('costToBreakCalculator', ($timeout, costToBreakCalculator) ->
    templateUrl: '/views/directives/nr-cost-to-break-calculator.html'
    restrict: 'E'
    scope: {
      card: '='
    }
    controller: 'CostToBreakCtrl'
    link: (scope, element, attrs) ->
      opponentsList = element.find('.opponents')

      # Scroll to the top of the list when the card changes
      scope.$watch 'card', ->
        $timeout -> opponentsList[0].scrollTop = 0
  )
