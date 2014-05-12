# Contains information about how elements of a search result should be sorted and 
# which are visible.
class QueryResult
  constructor: ->
    @orderedElements = []
    @orderingById = {}
    @groups = {}
    @length = 0
    # Used because groups and elements both exist in the same ordering space, but groups
    # do not contribute to the length of the query result. We use the offset to
    @_ordinalOffset = 0

  addNext: (element, group) ->
    @orderedElements.push(element)
    if !@orderingById[group.id]?
      @orderingById[group.id] = @length + @_ordinalOffset
      @groups[group.id] = group
      @_ordinalOffset++

    @orderingById[element.id] = @length + @_ordinalOffset
    @length++

  isShown: (id) ->
    @orderingById[id]?

  # Applies the query result's ordering to a collection of objects. idFn is applied
  # to each element in order to map the element to its associated result identifier.
  #
  # Elements that do not appear in the query results are placed at the end of the collection.
  applyOrdering: (collection, idFn) ->
    _.sortBy collection, (ele) =>
      @orderingById[idFn(ele)] ? Number.MAX_VALUE

  elementOrdinal: (ele) ->
    @orderedElements.indexOf(ele)

  # NOTE the equals sign. This is a helper function, not a method.
  _elementAtOffset = (offset) ->
    (ele) ->
      # NOTE, this could be optimized, but isn't likely a big deal
      idx = @orderedElements.indexOf(ele) + offset
      @orderedElements[idx]

  cardAfter: _elementAtOffset(1)
  cardBefore: _elementAtOffset(-1)

  # Returns an array of `count` elements before the specified element, and an array of count
  # afterwards. If there are not enough elements in the result, as many are returned as possible.
  beforeAndAfter: (ele, count) ->
    idx = @orderedElements.indexOf(ele)
    if idx == -1
      return [ [], [] ]

    before = @orderedElements.slice(Math.max(0, idx - count), idx)
    after =  @orderedElements.slice(start = idx + 1, start + count)
    [ before, after ]


angular.module('onoSendai').constant('QueryResult', QueryResult)
