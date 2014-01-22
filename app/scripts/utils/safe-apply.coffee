angular.module('onoSendai').run ($rootScope) ->
  $rootScope.$safeApply = (fn) ->
    if !@$$phase
      @$apply fn
    else
      fn()
