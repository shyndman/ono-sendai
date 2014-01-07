# Top navigation. Handles the quick card search.
#
# [todo] It's kind of messy to handle the card search in here. The autocomplete should be componentized.
angular.module('onoSendai')
  .directive('nrNav', ($document, cardService) ->
    maxResults = 10

    templateUrl: '/views/directives/nr-nav.html'
    replace: false
    restrict: 'E'
    controller: ($scope) ->
      $scope.previousResult = ->
        if $scope.cardSearchResults?.selectedIndex - 1 >= 0
          $scope.cardSearchResults.selectedIndex--

      $scope.nextResult = ->
        if $scope.cardSearchResults?.selectedIndex + 1 < $scope.cardSearchResults.length
          $scope.cardSearchResults.selectedIndex++

      $scope.selectResult = ->
        card = $scope.cardSearchResults[$scope.cardSearchResults.selectedIndex]
        if card?
          $scope.selectCard(card)
          $scope.cardSearch = ''

      $scope.$watch 'cardSearch', cardSearchChanged = (newVal) ->
        if _.isEmpty(newVal)
          $scope.cardSearchResults = []
          $scope.cardSearchResults.selectedIndex = 0
        else
          cardService.query(search: newVal, byTitle: true)
            .then (cards) ->
              $scope.cardSearchResults = cards.orderedCards.slice(0, maxResults)
              $scope.cardSearchResults.selectedIndex = 0

    link: (scope, element) ->
      cardSearch = element.find('.card-search .dropdown-parent')
      searchInput = element.find('.card-search input')

      scope.$watch 'cardSearchResults', cardSearchResultsChanged = (newVal) ->
        menuOpen = !!newVal.length
        cardSearch.toggleClass('open', menuOpen)



  )
