angular.module('onoSendai')
  .directive('nrSettings', ($document, $timeout) ->
    templateUrl: '/views/directives/nr-settings.html'
    restrict: 'E'
    link: (scope, element, attrs) ->


      # Hide on a document click
      $document.click (e) ->
        target = $(e.target)
        toggleElements = $(attrs.toggleSelector)

        # [todo] Factor this out into a jquery plugin
        return if _.any(toggleElements, (ele) -> ele == e.target) or
                  toggleElements.find(target).length > 0 or
                  element[0] == e.target or
                  element.find(target).length > 0

        scope.$safeApply -> scope.$eval(attrs.hide)
        return

    controller: ($scope, $document, cardService, userPreferences) ->
      cardService.getSets().then assignSets = ([ __, releasedSets ]) ->
        visibleSets = _.filter releasedSets, (set) -> set.title != 'Core Set'
        setsAndCycles = []
        setIdsByCycle = {}

        for set in visibleSets
          last = _.last(setsAndCycles)

          # If the set has a cycle, and it differs from the cycle of the last set encountered,
          # we're onto a new cycle and it should be added to the view model.
          if set.cycle? and (!last? or !last.cycle? or last.cycle != set.cycle)
            setsAndCycles.push type: 'cycle', title: set.cycle, id: _.idify(set.cycle)

          # Push a view model set
          baseSet =
            if set.cycle?
              type: 'set'
              cycleId: _.idify(set.cycle)
            else # Deluxe expansions
              type: 'solo-set'
          setsAndCycles.push _.extend(baseSet, set)

          # Associate the set ID with the cycle so that we can toggle all at once
          if set.cycle?
            (setIdsByCycle[baseSet.cycleId] ?= []).push(set.id)

        $scope.setsAndCycles = setsAndCycles
        $scope.setsOwned = userPreferences.setsOwned()

        # These two are used for set selection/deselection, and indeterminate checks
        $scope.cyclesOwned = {}
        $scope.partialCycles = {}

        # Update the users local storage with the sets owned when they change
        $scope.$watch('setsOwned', userPreferences.setsOwned, true)

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
