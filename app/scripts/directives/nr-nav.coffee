# Top navigation. Handles the quick card search.
#
# [todo] It's kind of messy to handle the card search in here. The autocomplete should be componentized, or possibly
#        merged with ui-dropdown (they're very similar).
angular.module('onoSendai')
  .directive('nrNav', ($document, $timeout, $location, $sce, cardService) ->
    maxResults = 10

    templateUrl: '/views/directives/nr-nav.html'
    replace: false
    restrict: 'E'
    controller: ($scope) ->

      # ~-~-~ Navigation

      $scope.isNavActive = (navPath) ->
        ///^#{ navPath }///.test($location.path())


      # ~-~-~ Jump to Card Autocomplete

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

      $scope.resultTitle = (card, searchTerm) ->
        title = card.title.replace(///#{searchTerm}///i, (match) -> "<span class='underlined'>#{match}</span>")
        $sce.trustAsHtml(title)

      $scope.$watch 'cardSearch', cardSearchChanged = (newVal) ->
        if _.isEmpty(newVal)
          $scope.cardSearchResults = []
          $scope.cardSearchResults.selectedIndex = 0
        else
          cardService.query(search: newVal, byTitle: true)
            .then (cards) ->
              $scope.cardSearchResults = cards.orderedElements.slice(0, maxResults)
              $scope.cardSearchResults.selectedIndex = 0

    link: (scope, element) ->
      cardSearch = element.find('.card-search .dropdown-parent')
      searchResults = cardSearch.find('.dropdown-menu')
      searchInput = element.find('.card-search input')

      # Special handling so that we can trigger a link click
      searchInput.keydown jwerty.event('enter', (e) ->
        cardSearch.find('.dropdown-menu li.active a').click()
        e.preventDefault())

      # Show the results if they'd been hidden by a document click if the search input regains focuss
      searchInput.focus (e) ->
        cardSearchResultsChanged(scope.cardSearchResults)

      # Don't let clicks propagate to the document
      searchInput.click (e) ->
        e.stopPropagation()

      # Clear the search input if a search result is selected
      searchResults.click (e) ->
        scope.clearSearch()

      # Close the search results flyout if the document is clicked
      $document.click (e) ->
        cardSearch.removeClass('open')

      scope.$watch 'cardSearchResults', cardSearchResultsChanged = (newVal) ->
        menuOpen = !!newVal.length
        cardSearch.toggleClass('open', menuOpen)
  )
