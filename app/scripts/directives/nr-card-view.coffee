angular.module('onoSendai')
  .controller('CardViewCtrl', ($scope, costToBreakCalculator, userPreferences, urlStateService) ->

    # ~-~-~- INITIALIZATION

    $scope.cardUI =
      page: urlStateService.cardPage ? 'info'
    $scope.wingCardCount = 5


    # ~-~-~- CARD CAROUSEL

    invalidateBeforeAfter = ->
      if !$scope.queryResult
        return

      card = $scope.card
      [ before, after ] = $scope.queryResult.beforeAndAfter(card, 7)

      # WEIRDORIFICA
      # Store the card an its immediate neighbours in the scope, so we can render all three of their images
      # and do a fast DOM switch on card switches
      cards = []
      cards.push({ class: 'prev-0',  card: _.last(before) }) if before.length
      cards.push({ class: 'current', card: card })
      cards.push({ class: 'next-0',  card: _.first(after) }) if after.length
      $scope.cardAndNeighbours = cards

      # WEIRDORIFICA - More of the same...
      # We splice the current card onto these lists so that angular can render them in ngRepeats and next/prev
      # card operations won't cause flashes.
      before.splice(before.length, 0, card)
      after.splice(0, 0, card)

      $scope.cardsBefore = before
      $scope.cardsAfter = after

    $scope.$watch 'selectedCard', selectedCardChanged = (card, oldCard) ->
      $scope.card = card

      if card?
        invalidateBeforeAfter()

        # Page stuff
        if $scope.cardUI.page == 'cost-to-break' and !$scope.isCostToBreakEnabled(card)
          $scope.cardUI.page = 'info'
      else
        $scope.cardsBefore = $scope.cardsAfter = []

    $scope.$watch 'queryResult', invalidateBeforeAfter


    # ~-~-~- CARD SHORTAGES

    # Returns true if the user has less than 3 of this card
    #
    # [todo] Take into consideration ownership of datapacks and # of core sets owned.
    $scope.isShortCard = (card) ->
      card.quantity < 3 and card.type != 'Identity'


    # ~-~-~- COST TO BREAK CALCULATOR

    $scope.isCostToBreakEnabled = costToBreakCalculator.isCardApplicable

    $scope.isCostToBreakVisible = (card) ->
      $scope.isCostToBreakEnabled(card) and $scope.cardUI.page == 'cost-to-break'

    $scope.$watch 'cardUI.page', pageChanged = (page) ->
      if page == 'cost-to-break' and $scope.card? and !$scope.isCostToBreakEnabled($scope.card)
        $scope.cardUI.page = 'info'
      else
        updateUrl()


    # ~-~-~- FAVOURITES

    # Toggles the favourite state of the provided card
    $scope.toggleFavourite = userPreferences.toggleCardFavourite

    # Returns true if the provided card is favourited
    $scope.isFavourite = userPreferences.isCardFavourite


    # ~-~-~- URL UPDATES

    # Limits URL updates. I find it distracting if it happens to ofter.
    updateUrl = _.debounce((updateUrlNow = ->
      selCard = $scope.card
      cardPage = $scope.cardUI.page
      # selCard && cardPage resolves to cardPage if selCard is truthy
      $scope.$apply -> urlStateService.updateUrl($scope.filter, selCard, selCard && cardPage)
    ), 500)
  )
  .directive('cardView', ->
    templateUrl: '/views/directives/nr-card-view.html'
    restrict: 'E'
    controller: 'CardViewCtrl'
    link: (scope, element, attrs) ->

  )
