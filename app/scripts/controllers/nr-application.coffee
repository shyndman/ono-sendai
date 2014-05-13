angular.module('onoSendai')
  .controller('ApplicationCtrl', ($scope, $http, $log, $q, cardService, userPreferences, urlStateService, queryArgDefaults) ->

    # ~-~-~- INITIALIZATION

    $scope.selectedCard = null
    $scope.queryArgs = urlStateService.queryArgs

    initialize = ([ cards, queryResult ]) ->
      $scope.uiState =
        section: 'cards'
        zoom: userPreferences.zoom() ? 0.50
        mainContent: urlStateService.mainContent
        settingsVisible: false

      $log.debug 'Assigning cards with initial query ordering'
      $scope.cards = queryResult.applyOrdering(cards, (card) -> card.id)

      setQueryResult(queryResult)

      selCard = _.findWhere(cards, id: urlStateService.selectedCardId)
      if selCard?
        $scope.selectCard(selCard)

      initializeQueryArgsWatch()
      initializeUrlSync()
      loadVersion()

    loadVersion = ->
      $http.get('/data/version.json').success(({ version, codename }) ->
        $scope.version = "v#{ version }"
        $scope.codename = codename)

    # Kick it all off
    $q.all([cardService.getCards(), cardService.query(urlStateService.queryArgs)]).then(initialize)


    # ~-~-~- CARD SELECTION

    $scope.selectCard = (card) ->
      if card == $scope.selectedCard
        return

      if card?
        $log.info "Selected card changing to #{ card.title }"

        # Note that we change layout mode to 'detail' when a card is supplied, but do not change it to 'grid'
        # when card == null. This is so that searches (in detail mode) don't boot us out to grid mode when
        # there are no results.
        $scope.uiState.mainContent = 'card'
      else
        $log.info 'Card deselected'

      $scope.selectedCard = card
      updateUrl()

    $scope.deselectCard = ->
      $scope.uiState.mainContent = 'cardGrid'
      $scope.selectCard(null)

    $scope.selectPreviousCard = ->
      if $scope.selectedCard is null
        return

      prevCard = $scope.queryResult.cardBefore($scope.selectedCard)
      if !prevCard?
        return

      $log.info 'Moving to previous card'
      $scope.selectCard(prevCard)

    $scope.selectNextCard = ->
      if $scope.selectedCard is null
        return

      nextCard = $scope.queryResult.cardAfter($scope.selectedCard)
      if !nextCard?
        return

      $log.info 'Moving to next card'
      $scope.selectCard(nextCard)


    #~-~-~- LAYOUT

    $scope.$watch 'uiState.mainContent', mainContentChanged = (mainContent) ->
      $scope.$broadcast 'layout', mainContent


    #~-~-~- QUERYING

    setQueryResult = (queryResult) ->
      $log.debug 'Assigning new query result', queryResult
      $scope.queryResult = queryResult

      selCard = $scope.selectedCard ? {}
      # If we're in detail mode, and the selected card isn't visible (or doesn't exist), select the first
      # query result.
      if $scope.uiState.mainContent == 'card' and !queryResult.isShown(selCard.id)
        $scope.selectCard(queryResult.orderedElements[0])

    initializeQueryArgsWatch = ->
      $scope.$watch('queryArgs', (queryArgsChanged = (queryArgs, oldQueryArgs) ->
        if angular.equals(queryArgs, oldQueryArgs)
          return

        updateUrl()
        cardService.query(queryArgs).then (queryResult) ->
          setQueryResult(queryResult)
      ), true) # True to make sure field changes trigger this watch

    # Resets query args, and deselects the selected card, if any
    $scope.resetState = ->
      $scope.deselectCard()
      $scope.queryArgs = _.extend(angular.copy(queryArgDefaults.get()), side: $scope.queryArgs.side)
      updateUrlNow(true)


    # ~-~-~- URL SYNC

    initializeUrlSync = ->
      # Watches for URL changes, to change application state
      $scope.$on('urlStateChange', urlChanged = ->
        selCard =
          if urlStateService.selectedCardId?
            card = _.findWhere($scope.cards, id: urlStateService.selectedCardId)
          else
            null

        if selCard?
          $scope.selectCard(selCard)
        else
          $scope.deselectCard()

        # Update these variables after selecting a card, overwriting any
        # changes to scope variables selectCard makes
        $scope.queryArgs = urlStateService.queryArgs
        $scope.uiState.section = urlStateService.section
        $scope.uiState.mainContent = urlStateService.mainContent)

    updateUrlNow = (pushState = false) ->
      selCard = $scope.selectedCard
      cardPage = $scope.uiState.cardPage
      $scope.$safeApply ->
        urlStateService.updateUrl($scope.queryArgs, selCard,
          selCard && cardPage, null, pushState) # [todo] selectedDeck

    # Limits URL updates. I find it distracting if it happens to ofter.
    updateUrl = _.debounce(updateUrlNow, 500)


    # ~-~-~- TOGGLING SETTINGS

    $scope.showSettings = ->
      $scope.uiState.settingsVisible = true

    $scope.hideSettings = ->
      if $scope.uiState.settingsVisible
        $scope.uiState.settingsVisible = false
        true
      else
        false


    # ~-~-~- PERSISTING PREFERENCES

    $scope.$watch 'queryArgs.fieldFilters.showSpoilers', persistShowSpoilers = (flag) ->
      if flag?
        userPreferences.showSpoilers(flag)


    # ~-~-~- COMMUNICATION BETWEEN DIRECTIVES / CONTROLLERS

    $scope.broadcastZoomStart = ->
      $scope.$broadcast 'zoomStart'

    $scope.broadcastZoomEnd = ->
      $scope.$broadcast 'zoomEnd'
      userPreferences.zoom($scope.uiState.zoom)
  )
