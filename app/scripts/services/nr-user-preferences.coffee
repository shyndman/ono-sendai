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
