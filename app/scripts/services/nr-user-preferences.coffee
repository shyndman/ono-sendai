# Retrieves and stores user preferences -- things like favourite cards, custom card tags,
# notes on cards, etcetera etc.
#
# Currently this stores everything in DOM Local Storage, but could persist to the server at
# some point.
class UserPreferences
  constructor: ->
    @_favs =      JSON.parse(localStorage.getItem('favourites') + '') ? {}
    @_setsOwned = JSON.parse(localStorage.getItem('setsOwned')  + '') ? { 'core-sets': 1 }

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

  setsOwned: (sets) =>
    if sets?
      sets['core-sets'] = parseInt(sets['core-sets'])
      @_setsOwned = sets
      @_persistSetsOwned()
    else
      @_setsOwned

  _persistSetsOwned: =>
    localStorage.setItem('setsOwned', JSON.stringify(@_setsOwned))

  _persistFavourites: =>
    localStorage.setItem('favourites', JSON.stringify(@_favs))

angular.module('onoSendai')
  .service 'userPreferences', () ->
    new UserPreferences(arguments...)
