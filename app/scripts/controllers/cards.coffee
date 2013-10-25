angular.module('deckBuilder')
  .controller('CardsCtrl', (cardService, $scope, $window) ->

    $scope.grid = zoom: 0.5

    linearizeCardGroups = (cardGroups) ->
      _(cardGroups)
        .chain()
        .map((group) ->
          [_.extend(group, isHeader: true), group.cards])
        .flatten()
        .value()

    $scope.$watch('filter', ((filter)->
      # NOTE
      # We don't directly assign the promise, because if we do, even cards that
      # didn't get filtered out will have new DOM nodes created, rather than reusing
      # the old ones.
      cardService.getCards(filter).then (cardGroups) ->
        $scope.cardsAndGroups = linearizeCardGroups(cardGroups)

    ), true)) # True to make sure field changes trigger this watch
