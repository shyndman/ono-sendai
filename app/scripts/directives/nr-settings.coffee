angular.module('onoSendai')
  .directive('nrSettings', (cardService) ->
    templateUrl: '/views/directives/nr-settings.html'
    restrict: 'E'
    link: (scope, element, attrs) ->
      cardService.getSets().then assignSets = ([ __, releasedSets ]) ->
        visibleSets = _.filter releasedSets, (set) -> set.title != 'Core Set'
        cycles = []
        # for set in visibleSets
        #   if _.last(cycles).title == set.cycle
        # cycleGroups =

        scope.sets = visibleSets
  )
