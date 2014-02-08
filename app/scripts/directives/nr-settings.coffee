angular.module('onoSendai')
  .directive('nrSettings', ($document, $timeout) ->
    templateUrl: '/views/directives/nr-settings.html'
    restrict: 'E'
    link: (scope, element, attrs) ->
      # [todo] Hide on document click
      # $document.click (e) ->
      #   scope.$safeApply -> scope.$eval(attrs.hide)

    controller: ($scope, $document, cardService, userPreferences) ->
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
            partial = partial && !$scope.cyclesOwned[cycleId]
            $scope.partialCycles[cycleId] = partial

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
