angular.module('deckBuilder')
  .controller('CardsCtrl', ($rootScope, $scope, $http, $log, $q, cardService, userPreferences, urlStateService) ->
    $scope.filter = urlStateService.generatedQueryArgs
    $scope.grid = zoom: 0.5
    $scope.selectedCard = null
    $http.get('/data/version.json').success((data) ->
      $scope.version = data.version)

    # Assign cards to the scope once, but order them according to the initial query so the first images
    # to load are the ones on screen.
    $q.all([cardService.getCards(), cardService.query($scope.filter)])
      .then(([ cards, queryResult ]) ->
        $log.debug 'Assigning cards with initial query ordering'
        $scope.cards = queryResult.applyOrdering(cards, (card) -> card.id)

        if urlStateService.selectedCardId?
          $scope.selectCard(_.findWhere(cards, id: urlStateService.selectedCardId)))

    $rootScope.broadcastZoomStart = ->
      $scope.$broadcast 'zoomStart'

    $rootScope.broadcastZoomEnd = ->
      $scope.$broadcast 'zoomEnd'

    $scope.selectCard = (card) ->
      if card?
        $log.info "Selected card changing to #{ card.title }"
      else
        $log.info 'Card deselected'

      $scope.selectedCard = card
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

    # Returns true if the user has less than 3 of this card
    #
    # TODO Take into consideration ownership of datapacks and # of core sets owned.
    $scope.isShortCard = (card) ->
      card.quantity < 3 and card.type != 'Identity'

    # Toggles the favourite state of the provided card
    $scope.toggleFavourite = userPreferences.toggleCardFavourite

    # Returns true if the provided card is favourited
    $scope.isFavourite = userPreferences.isCardFavourite

    setQueryResult = (queryResult) ->
      $log.debug 'Assigning new query result', queryResult
      $scope.queryResult = queryResult

      selCard = $scope.selectedCard
      if selCard and !queryResult.isShown(selCard.id)
        $scope.selectCard(queryResult.orderedCards[0])

    # Watches for URL changes, to change selectedCard/
    $scope.$on 'urlStateChange', ->
      $scope.filter = urlStateService.generatedQueryArgs
      $scope.selectCard(_.findWhere($scope.cards, id: urlStateService.selectedCardId))

    # Limits URL updates. I find it distracting if it happens to ofter.
    updateUrl = _.debounce((->
      $scope.$apply -> urlStateService.updateUrl($scope.filter, $scope.selectedCard)
    ), 500)

    $scope.$watch('filter', ((filter, oldFilter) ->
      updateUrl()
      cardService.query(filter).then (queryResult) ->
        setQueryResult(queryResult)
    ), true)) # True to make sure field changes trigger this watch
