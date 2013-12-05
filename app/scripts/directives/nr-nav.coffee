# Top navigation. Handles the quick card search.
angular.module('onoSendai')
  .directive('nrNav', (cardService) ->
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
      cardSearch = element.find('.card-search')
      scope.$watch 'cardSearchResults', cardSearchResultsChanged = (newVal) ->
        cardSearch.toggleClass('open', !!newVal.length)



  )
