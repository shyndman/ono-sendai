# Top navigation. Handles the quick card search.
#
# [todo] It's kind of messy to handle the card search in here. The autocomplete should be componentized.
angular.module('onoSendai')
  .directive('nrNav', ($document, cardService, $timeout) ->
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

      # Clears the search field if there is a currently selected result. The page navigation is handled
      # in the link function below.
      $scope.clearSearch = ->
        card = $scope.cardSearchResults[$scope.cardSearchResults.selectedIndex]
        if card?
          # Allow other handlers to run
          $timeout -> $scope.cardSearch = ''

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

      # Special handling so that we can trigger a link click
      searchInput.keydown jwerty.event('enter', (e) ->
        cardSearch.find('.dropdown-menu li.active a').click()
        e.preventDefault())

      scope.$watch 'cardSearchResults', cardSearchResultsChanged = (newVal) ->
        menuOpen = !!newVal.length
        cardSearch.toggleClass('open', menuOpen)
  )
