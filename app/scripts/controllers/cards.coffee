angular.module('onoSendai')
  .controller('CardsCtrl', ($scope, $http, $log, $q, cardService, costToBreakCalculator, userPreferences, urlStateService) ->

    # ~-~-~- INITIALIZATION

    $scope.filter = urlStateService.queryArgs
    $scope.cardUI =
      zoom: 0.35
      costToBreakVisible: false
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
      else
        $log.info 'Card deselected'

      $scope.selectedCard = card

      if costToBreakCalculator.isCardApplicable(card)
        $scope.costToBreakInfo = costToBreakCalculator.calculate($scope.selectedCard)

      updateUrl()

    $scope.deselectCard = ->
      $scope.selectCard(null)

    $scope.previousCard = ->
      if $scope.selectedCard is null
        return

      prevCard = $scope.queryResult.cardBefore($scope.selectedCard)
      if !prevCard?
        return

      $log.info 'Moving to previous card'
      $scope.selectCard(prevCard)

    $scope.nextCard = ->
      if $scope.selectedCard is null
        return

      nextCard = $scope.queryResult.cardAfter($scope.selectedCard)
      if !nextCard?
        return

      $log.info 'Moving to next card'
      $scope.selectCard(nextCard)


    # ~-~-~- CARD COUNTS

    # Returns true if the user has less than 3 of this card
    #
    # [todo] Take into consideration ownership of datapacks and # of core sets owned.
    $scope.isShortCard = (card) ->
      card.quantity < 3 and card.type != 'Identity'


    # ~-~-~- COST TO BREAK CALCULATOR

    $scope.isCostToBreakEnabled = costToBreakCalculator.isCardApplicable


    # ~-~-~- FAVOURITES

    # Toggles the favourite state of the provided card
    $scope.toggleFavourite = userPreferences.toggleCardFavourite

    # Returns true if the provided card is favourited
    $scope.isFavourite = userPreferences.isCardFavourite


    #~-~-~- QUERYING

    setQueryResult = (queryResult) ->
      $log.debug 'Assigning new query result', queryResult
      $scope.queryResult = queryResult

      selCard = $scope.selectedCard
      if selCard and !queryResult.isShown(selCard.id)
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
      $scope.$apply -> urlStateService.updateUrl($scope.filter, $scope.selectedCard)
    ), 500)


    $scope.broadcastZoomStart = ->
      $scope.$broadcast 'zoomStart'

    $scope.broadcastZoomEnd = ->
      $scope.$broadcast 'zoomEnd'
  )
