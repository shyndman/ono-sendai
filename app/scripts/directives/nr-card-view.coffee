angular.module('onoSendai')
  .controller('CardViewCtrl', ($scope, costToBreakCalculator, userPreferences, urlStateService) ->
    # ~-~-~- INITIALIZATION

    $scope.page = 'info'
    $scope.wingCardCount = 5


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

    $scope.$watch('page', pageChanged = (page) ->
      if page == 'cost-to-break' and $scope.selectedCard? and !$scope.isCostToBreakEnabled($scope.selectedCard)
        $scope.page = 'info'
      else
        updateUrl())


    # ~-~-~- FAVOURITES

    # Toggles the favourite state of the provided card
    $scope.toggleFavourite = userPreferences.toggleCardFavourite

    # Returns true if the provided card is favourited
    $scope.isFavourite = userPreferences.isCardFavourite


    # ~-~-~- URL UPDATES

    # Limits URL updates. I find it distracting if it happens to ofter.
    updateUrl = _.debounce((updateUrlNow = ->
      selCard = $scope.card
      cardPage = $scope.page
      $scope.$apply -> urlStateService.updateUrl($scope.filter, selCard, selCard && cardPage)
    ), 500)
  )
  .directive('cardView', ->
    templateUrl: '/views/directives/nr-card-view.html'
    restrict: 'E'
    controller: 'CardViewCtrl'
    scope: {
      card: '='
      queryResult: '='
    }
    link: (scope, element, attrs) ->

  )
