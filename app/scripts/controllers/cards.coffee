angular.module('deckBuilder')
  .controller('CardsCtrl', (cardService, $scope) ->

    $scope.$watch('filter', ((filter)->
      # We don't directly assign the promise, because if we do, even cards that
      # didn't get filtered out will have new DOM nodes created, rather than reusing
      # the old ones.
      cardService.getCards(filter).then((cardGroups) ->
        $scope.cardGroups = cardGroups)
    ), true))
