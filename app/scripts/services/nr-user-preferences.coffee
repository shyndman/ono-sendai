# Retrieves and stores user preferences -- things like favourite cards, custom card tags,
# notes on cards, etcetera etc.
#
# Currently this stores everything in DOM Local Storage, but could persist to the server at
# some point.
class UserPreferences

  constructor: ->
    @_favs =      JSON.parse(localStorage.getItem('favourites') + '') ? {}
    @_setsOwned = JSON.parse(localStorage.getItem('setsOwned')  + '') ? 'core-set': 0

  isCardFavourite: (card) =>
    @_favs[card.id] ? false

  toggleCardFavourite: (card) =>
    @_favs[card.id] = !@isCardFavourite(card)
    @_persistFavourites()

  showSpoilers: (flag) =>
    if flag?
      localStorage.setItem('showSpoilers', flag)
    else
      JSON.parse(localStorage.getItem('showSpoilers'))

  zoom: (zoom) =>
    if zoom?
      localStorage.setItem('zoom', zoom)
    else
      localStorage.getItem('zoom')

  # Returns true if the user has configurd their set ownership
  hasConfiguredSets: =>
    !!@dateSetsConfigured()

  # Returns the date the user last configured their sets
  dateSetsConfigured: (dateConfigured) =>
    if dateConfigured?
      localStorage.setItem('dateSetsConfigured', dateConfigured.toISOString())
    else if isoDate = localStorage.getItem('dateSetsConfigured')?
      new Date(isoDate)
    else
      null

  # Returns the quantity of a set owned by the player
  quantityOfSet: (setNameOrId) ->
    owned = @_setsOwned[_.idify(setNameOrId)]
    if !owned?
      0
    else if _.isNumber(owned)
      owned
    else if owned == true
      1
    else # owned == false
      0

  setsOwned: (sets) =>
    if sets?
      sets['core-set'] = parseInt(sets['core-set'])

      # Mark when the user last configured set ownership
      if !angular.equals(@_setsOwned, sets)
        @dateSetsConfigured(new Date())

      # We need to copy the sets hash so that we can perform future comparisons.
      @_setsOwned = angular.copy(sets)
      @_persistSetsOwned()
    else
      # We need to copy the sets hash so that we can perform the comparison
      # in the setter.
      angular.copy(@_setsOwned)

  _persistSetsOwned: =>
    localStorage.setItem('setsOwned', JSON.stringify(@_setsOwned))

  _persistFavourites: =>
    localStorage.setItem('favourites', JSON.stringify(@_favs))

angular.module('onoSendai')
  .service 'userPreferences', () ->
    new UserPreferences(arguments...)
