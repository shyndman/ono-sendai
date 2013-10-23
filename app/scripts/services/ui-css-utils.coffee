# Provides common CSS utilities (to directives)
class CssUtils
  constructor: (@$window) ->
    @div = @$window.document.createElement('div')

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
  cssDurationToMs = (duration) ->
    if match = duration.match /(\d+)ms/
      Number(match[1])
    else if match = duration.match /(\d+(\.\d+)?)s/
      Number(match[1]) * 1000

  # Returns the total duration of an item's transition, including delay.
  # WARNING This assumes a single transitioned property.
  getTransitionDuration: (item) ->
    transitionProperty = @getVendorPropertyName('transition')
    transitionValues = @$window.getComputedStyle(item[0])[transitionProperty].split(/\s+/)
    @cssDurationToMs(transitionValues[1]) + @cssDurationToMs(transitionValues[3])

angular.module('deckBuilder')
  .service 'cssUtils', ($window) -> new CssUtils($window)

