angular.module('onoSendai')
  .directive('nrSettings', ($timeout) ->
    templateUrl: '/views/directives/nr-settings.html'
    restrict: 'E'
    controller: ($scope, cardService, userPreferences) ->
      cardService.getSets().then assignSets = ([ __, releasedSets ]) ->
        visibleSets = _.filter releasedSets, (set) -> set.title != 'Core Set'
        setsAndCycles = []
        setIdsByCycle = {}

        for set in visibleSets
          last = _.last(setsAndCycles)
          if set.cycle? and (!last? or !last.cycle? or last.cycle != set.cycle)
            setsAndCycles.push type: 'cycle', title: set.cycle, id: _.idify(set.cycle)

          # Push a view model set
          baseSet =
            if set.cycle?
              type: 'set'
              cycleId: _.idify(set.cycle)
            else
              type: 'solo-set'
          setsAndCycles.push _.extend(baseSet, set)

          # Associate the set ID with the cycle so that we can toggle all at once
          if set.cycle?
            (setIdsByCycle[baseSet.cycleId] ?= []).push(set.id)

        console.log setsAndCycles

        $scope.setsAndCycles = setsAndCycles
        $scope.cyclesOwned = {}
        $scope.partialCycles = {}
        $scope.setsOwned = userPreferences.setsOwned()

        $scope.$watch('setsOwned', ((newSets) ->
          userPreferences.setsOwned(newSets)
        ), true)

        # Walks through all the cycles to determine what sets are owned, partially owned,
        # or not owned at all.
        updateCyclesOwned = ->
          for cycleId, setIds of setIdsByCycle
            $scope.cyclesOwned[cycleId] = _.all setIds, (sId) ->
              $scope.setsOwned[sId]
            partial = _.any setIds, (sId) ->
              $scope.setsOwned[sId]

            # A partial cycle is one where we have at least one set owned, but not all
            console.error partial, !$scope.cyclesOwned[cycleId]
            partial = partial && !$scope.cyclesOwned[cycleId]
            $scope.partialCycles[cycleId] = partial
          console.error '$scope.partialCycles', $scope.partialCycles

          return

        updateCyclesOwned()

        $scope.setToggled = (set) ->
          if !set.cycle?
            return
          updateCyclesOwned()

        $scope.cycleToggled = (cycle, flag) ->
          for setId in setIdsByCycle[cycle.id]
            $scope.setsOwned[setId] = flag
  )
