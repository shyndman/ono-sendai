# Retrieves and stores user preferences -- things like favourite cards, custom card tags,
# notes on cards, etcetera etc.
#
# Currently this stores everything in DOM Local Storage, but could persist to the server at
# some point.
class UserPreferences
  constructor: ->
    @_favs = JSON.parse(localStorage.getItem('favourites') + '') ? {}

  isCardFavourite: (card) =>
    @_favs[card.id] ? false

  toggleCardFavourite: (card) =>
    @_favs[card.id] = !@isCardFavourite(card)
    @_persistFavourites()

  _persistFavourites: =>
    localStorage.setItem("favourites", JSON.stringify(@_favs))

angular.module('deckBuilder')
  .service 'userPreferences', () ->
    new UserPreferences(arguments...)
