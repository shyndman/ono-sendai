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

  # Takes a CSS duration value, and converts it into a number representing the number of milliseconds.
  cssDurationToMs: (duration) ->
    if match = duration.match /(\d+)ms/
      Number(match[1])
    else if match = duration.match /(\d+(\.\d+)?)s/
      Number(match[1]) * 1000

  cssPixelLengthToNumber: (length) ->
    if length
      match = length.match /^(\d+(\.\d+)?)/
      Number(match[1])
    else
      0

  # Returns the total duration of an item's transition, including delay.
  # WARNING This assumes a single transitioned property.
  getTransitionDuration: (item, computedStyle = @$window.getComputedStyle(@_node(item))) ->
    transitionValues = computedStyle[@transitionProperty].split(/\s+/)
    @cssDurationToMs(transitionValues[1]) + @cssDurationToMs(transitionValues[3])

  # Returns a promise that will be resolved when the items transition completes.
  getTransitionEndPromise: (item) ->
    deferred = @$q.defer()
    item.one @transitionEndEvent, onEnd = =>
      @$log.debug 'Transition complete'
      deferred.resolve()
    deferred.promise

  _node: (item) ->
    if item instanceof $
      item.get(0)
    else
      item

angular.module('onoSendai')
  .service 'cssUtils', ($window, $q, $log) -> new CssUtils($window, $q, $log)

