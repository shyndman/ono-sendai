angular.module('onoSendai')
  .controller('CardViewCtrl', ($scope, costToBreakCalculator, cardService, userPreferences, urlStateService) ->

    # ~-~-~- INITIALIZATION

    $scope.wingCardCount = 5


    # ~-~-~- CARD CAROUSEL

    invalidateBeforeAfter = ->
      if !$scope.queryResult
        return

      card = $scope.card
      [ before, after ] = $scope.queryResult.beforeAndAfter(card, $scope.wingCardCount)

      # WEIRDORIFICA
      # Store the card an its immediate neighbours in the scope, so we can render all three of their images
      # and do a fast DOM switch on card switches. This will prevent flashes (most of the time) as the image
      # loads.
      cards = []
      cards.push(class: 'prev-0',  card: _.last(before)) if before.length
      cards.push(class: 'current', card: card)
      cards.push(class: 'next-0',  card: _.first(after)) if after.length
      $scope.cardAndNeighbours = cards

      before.splice(before.length, 0, card)
      after.splice(0, 0, card)

      $scope.cardsBefore = before
      $scope.cardsAfter = after

    $scope.$watch 'selectedCard', selectedCardChanged = (card, oldCard) ->
      $scope.card = card
      $scope.cardUI =
        page: urlStateService.cardPage ? 'info'
        altArtShown: false

      if card?
        invalidateBeforeAfter()

        # Page stuff
        if $scope.cardUI.page == 'cost-to-break' and !$scope.isCostToBreakEnabled(card)
          $scope.cardUI.page = 'info'
      else
        $scope.cardsBefore = $scope.cardsAfter = []

    $scope.$watch 'queryResult', invalidateBeforeAfter


    # ~-~-~- SPOILERS

    $scope.isUnreleased = (card) ->
      !cardService.getSetByTitle(card.setname).isReleased()


    # ~-~-~- CARD SHORTAGES

    # Returns true if the user has less than 3 of this card
    $scope.isShortCard = (card) ->
      if card.type == 'Identity'
        $scope.cardQuantity(card) < 1
      else
        $scope.cardQuantity(card) < 3

    # Returns the number of cards owned by the player
    $scope.cardQuantity = (card) ->
      card.quantity * userPreferences.quantityOfSet(card.setname)

    # Returns true if the user has manually configured set ownership
    $scope.hasConfiguredSets = userPreferences.hasConfiguredSets


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


    # ~-~-~- ALTERNATE ART

    $scope.hasAltArt = (card) ->
      card.altart?

    $scope.toggleAltArt = (card) ->
      $scope.cardUI.altArtShown = !$scope.cardUI.altArtShown


    # ~-~-~- URL UPDATES

    # Limits URL updates. I find it distracting if it happens to ofter.
    updateUrl = _.debounce((updateUrlNow = ->
      selCard = $scope.card
      cardPage = $scope.cardUI.page
      # selCard && cardPage resolves to cardPage if selCard is truthy
      $scope.$apply -> urlStateService.updateUrl($scope.queryArgs, selCard, selCard && cardPage)
    ), 500)
  )
  .directive('cardView', ->
    templateUrl: '/views/directives/nr-card-view.html'
    restrict: 'E'
    controller: 'CardViewCtrl'
    link: (scope, element, attrs) ->
  )
