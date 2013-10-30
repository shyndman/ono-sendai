angular.module('deckBuilder')
  .controller('CardsCtrl', ($rootScope, $scope, $window, $log, $q, cardService, urlStateService) ->
    $scope.selectedCard = null

    # Assign cards to the scope once, but order them according to the default filter so the first images
    # to load are the ones on screen.
    $q.all([cardService.getCards(), cardService.query($scope.filter)])
      .then(([ cards, queryResult ]) ->
        $log.debug 'Assigning cards with default ordering'
        $scope.cards = queryResult.applyOrdering(cards, (card) -> card.id))

    $rootScope.broadcastZoomStart = ->
      $scope.$broadcast 'zoomStart'

    $rootScope.broadcastZoomEnd = ->
      $scope.$broadcast 'zoomEnd'

    $scope.selectCard = (card) ->
      $log.info "Selected card changing to #{ card.title }"
      $scope.selectedCard = card

    $scope.deselectCard = ->
      $log.info 'Card deselected'
      $scope.selectedCard = null

    $scope.isCardShown = (card, cardFilter) ->
      cardFilter[card.id]?

    # Limits URL updates. I find it distracting if it happens to ofter.
    updateUrl = _.debounce(((filter) ->
      $scope.$apply -> urlStateService.updateUrl(filter)
    ), 500)

    $scope.$watch('filter', ((filter)->
      $log.debug 'Filter changed'
      updateUrl(filter)
      cardService.query(filter).then (queryResult) ->
        $log.debug 'Assigning new query result', queryResult
        $scope.queryResult = queryResult
    ), true)) # True to make sure field changes trigger this watch
