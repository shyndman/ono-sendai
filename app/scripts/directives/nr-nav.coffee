# Top navigation. Handles the quick card search.
angular.module('onoSendai')
  .directive('nrNav', ($document, cardService) ->
    maxResults = 10

    templateUrl: '/views/directives/nr-nav.html'
    replace: false
    restrict: 'E'
    controller: ($scope) ->
      $scope.$watch 'cardSearch', cardSearchChanged = (newVal) ->
        if _.isEmpty(newVal)
          $scope.cardSearchResults = []
        else
          cardService.query(search: newVal)
            .then (cards) ->
              $scope.cardSearchResults = cards.orderedCards.slice(0, maxResults)

    link: (scope, element) ->
      cardSearch = element.find('.card-search .dropdown-parent')

      scope.$watch 'cardSearchResults', cardSearchResultsChanged = (newVal) ->
        menuOpen = !!newVal.length
        cardSearch.toggleClass('open', menuOpen)

  )
