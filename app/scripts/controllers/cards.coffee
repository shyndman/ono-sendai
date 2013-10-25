angular.module('deckBuilder')
  .controller('CardsCtrl', ($rootScope, $scope, $window, $log, cardService) ->
    $scope.selectedCard = null

    cardService.getCards().then((cards) ->
      $log.debug 'Assigning cards'
      $scope.cards = cards)

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

    $scope.$watch('filter', ((filter)->
      $log.debug 'Filter changed. Rebuilding filter map'
      cardService.buildFilterMap(filter).then (cardFilter) ->
        $log.debug 'Assigning new card filter'
        $scope.cardFilter = cardFilter
    ), true)) # True to make sure field changes trigger this watch
