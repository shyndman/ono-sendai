# Provides common CSS utilities (to directives)
class CssUtils
  # Maps transition style property names to their associated event types
  TRANSITION_END_EVENTS =
    'WebkitTransition' : 'webkitTransitionEnd'
    'MozTransition'    : 'transitionend'
    'OTransition'      : 'oTransitionEnd otransitionend'
    'transition'       : 'transitionend'

  constructor: (@$window, @$q, @$log) ->
    @div = @$window.document.createElement('div')
    @transitionProperty = @getVendorPropertyName('transition')
    @transitionEndEvent = TRANSITION_END_EVENTS[@transitionProperty]

  # Returns a the name of a CSS property when given the base name.
  # i.e. An argument of "transform" may return "WebkitTransform".
  getVendorPropertyName: _.memoize (prop) ->
    if prop of @div.style
      return prop

    prefixes = ['Moz', 'Webkit', 'O', 'ms']
    prop = _.capitalize(prop)

    if prop of @div.style
      return prop

    for prefix in prefixes
      vendorProp = prefix + prop
      if vendorProp of @div.style
        return vendorProp


angular.module('onoSendai')
  .service 'cssUtils', ($window, $q, $log) -> new CssUtils($window, $q, $log)

