# Provides common CSS utilities (to directives)
class CssUtils
  constructor: (@$window) ->
    @div = @$window.document.createElement('div')
    @transitionProperty = @getVendorPropertyName('transition')

  # Higher order function for generating computed property length property getters.
  @_lengthProperty: (propName) ->
    (item, computedStyle = @$window.getComputedStyle(@_node(item))) ->
      px = computedStyle[propName]
      @cssPixelLengthToNumber(px)

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

  getComputedHeight       : @_lengthProperty('height')
  getComputedWidth        : @_lengthProperty('width')
  getComputedTopMargin    : @_lengthProperty('topMargin')
  getComputedRightMargin  : @_lengthProperty('rightMargin')
  getComputedBottomMargin : @_lengthProperty('bottomMargin')
  getComputedLeftMargin   : @_lengthProperty('leftMargin')
  _getComputedMargin      : @_lengthProperty('margin')

  getComputedMargin: (item, computedStyle = @$window.getComputedStyle(@_node(item))) ->
    margin = @_getComputedMargin(item, computedStyle)

    top:    @getComputedTopMargin(item, computedStyle) || margin
    right:  @getComputedRightMargin(item, computedStyle) || margin
    bottom: @getComputedBottomMargin(item, computedStyle) || margin
    left:   @getComputedLeftMargin(item, computedStyle) || margin

  _node: (item) ->
    if item instanceof $
      item.get(0)
    else
      item

angular.module('deckBuilder')
  .service 'cssUtils', ($window) -> new CssUtils($window)

