angular.module('onoSendai')
  .controller('CardsCtrl', ($scope, $http, $log, $q, cardService, costToBreakCalculator, userPreferences, urlStateService) ->

    # ~-~-~- INITIALIZATION

    $scope.filter = urlStateService.queryArgs
    $scope.cardUI =
      zoom: 0.35
      # [todo] This should maybe be pushed down
      cardPage: urlStateService.cardPage ? 'info'
      layoutMode: if urlStateService.selectedCardId then 'detail' else 'grid'

    $scope.selectedCard = null
    $http.get('/data/version.json').success((data) ->
      $scope.version = data.version)

    # Assign cards to the scope once, but order them according to the initial query so the first images
    # to load are the ones on screen.
    $q.all([cardService.getCards(), cardService.query($scope.filter)])
      .then(setInitialCards = ([ cards, queryResult ]) ->
        $log.debug 'Assigning cards with initial query ordering'

        orderedCards = queryResult.applyOrdering(cards, (card) -> card.id)

        if urlStateService.selectedCardId?
          card = _.findWhere(orderedCards, id: urlStateService.selectedCardId)

          # If we found a selected card, we're going to reorder the cards so they load in-order, pivoted
          # around the selected card.
          if card?
            cardIdx = _.indexOf(orderedCards, card)
            [before, after] = _.splitAt(orderedCards, cardIdx)
            orderedCards = _.weave(before.reverse(), after)
            $scope.selectCard(card)

        $scope.cards = orderedCards)


    # ~-~-~- CARD SELECTION

    $scope.selectCard = (card) ->
      if card?
        $log.info "Selected card changing to #{ card.title }"

        # Note that we change layout mode to 'detail' when a card is supplied, but do not change it to 'grid'
        # when card == null. This is so that searches (in detail mode) don't boot us out to grid mode when
        # there are no results.
        $scope.cardUI.layoutMode = 'detail'
        $scope.previousCard = $scope.queryResult.cardBefore(card)
        $scope.nextCard = $scope.queryResult.cardAfter(card)

        if $scope.cardUI.cardPage == 'cost-to-break' and !$scope.isCostToBreakEnabled(card)
          $scope.cardUI.cardPage = 'info'
      else
        $log.info 'Card deselected'

      $scope.selectedCard = card

      updateUrl()

    $scope.deselectCard = ->
      $scope.cardUI.layoutMode = 'grid'
      $scope.selectCard(null)

    $scope.selectPreviousCard = ->
      if $scope.selectedCard is null
        return

      prevCard = $scope.queryResult.cardBefore($scope.selectedCard)
      if !prevCard?
        return

      $log.info 'Moving to previous card'
      $scope.selectCard(prevCard)

    $scope.selectNextCard = ->
      if $scope.selectedCard is null
        return

      nextCard = $scope.queryResult.cardAfter($scope.selectedCard)
      if !nextCard?
        return

      $log.info 'Moving to next card'
      $scope.selectCard(nextCard)


    # ~-~-~- CARD SHORTAGES

    # Returns true if the user has less than 3 of this card
    #
    # [todo] Take into consideration ownership of datapacks and # of core sets owned.
    $scope.isShortCard = (card) ->
      card.quantity < 3 and card.type != 'Identity'


    # ~-~-~- COST TO BREAK CALCULATOR

    $scope.isCostToBreakEnabled = costToBreakCalculator.isCardApplicable

    $scope.isCostToBreakVisible = (card) ->
      if !card?
        false
      else
        $scope.isCostToBreakEnabled(card) and $scope.cardUI.cardPage == 'cost-to-break'

    $scope.$watch('cardUI.cardPage', pageChanged = (page) ->
      if page == 'cost-to-break' and $scope.selectedCard? and !$scope.isCostToBreakEnabled($scope.selectedCard)
        $scope.cardUI.cardPage = 'info'
      else
        updateUrl())


    # ~-~-~- FAVOURITES

    # Toggles the favourite state of the provided card
    $scope.toggleFavourite = userPreferences.toggleCardFavourite

    # Returns true if the provided card is favourited
    $scope.isFavourite = userPreferences.isCardFavourite


    #~-~-~- QUERYING

    setQueryResult = (queryResult) ->
      $log.debug 'Assigning new query result', queryResult
      $scope.queryResult = queryResult

      selCard = $scope.selectedCard ? {}
      # If we're in detail mode, and the selected card isn't visible (or doesn't exist), select the first
      # query result.
      if $scope.cardUI.layoutMode == 'detail' and !queryResult.isShown(selCard.id)
        $scope.selectCard(queryResult.orderedCards[0])

    $scope.$watch('filter', (filterChanged = (filter, oldFilter) ->
      updateUrl()
      cardService.query(filter).then (queryResult) ->
        setQueryResult(queryResult)
    ), true) # True to make sure field changes trigger this watch


    # ~-~-~- URL SYNC

    # Watches for URL changes, to change selectedCard/
    $scope.$on('urlStateChange', urlChanged = ->
      $scope.filter = urlStateService.queryArgs
      card = _.findWhere($scope.cards, id: urlStateService.selectedCardId)
      $scope.selectCard(card))

    # Limits URL updates. I find it distracting if it happens to ofter.
    updateUrl = _.debounce((updateUrlNow = ->
      selCard = $scope.selectedCard
      cardPage = $scope.cardUI.cardPage
      $scope.$apply -> urlStateService.updateUrl($scope.filter, selCard, cardPage)
    ), 500)


    # ~-~-~- COMMUNICATION BETWEEN DIRECTIVES / CONTROLLERS

    $scope.broadcastZoomStart = ->
      $scope.$broadcast 'zoomStart'

    $scope.broadcastZoomEnd = ->
      $scope.$broadcast 'zoomEnd'
  )
