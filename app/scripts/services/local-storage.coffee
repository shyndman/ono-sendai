# Thin wrapper around LocalStorage that provides JSON (de/)serialization.
class LocalStorageUtil

  getItem: (key) ->
    JSON.parse(localStorage.getItem(key) ? 'null')

  setItem: (key, obj) ->
    localStorage.setItem(key, JSON.stringify(obj))

  getDate: (key) ->
    if (isoDate = localStorage.getItem(key))?
      new Date(isoDate)
    else
      null

  setDate: (key, date) ->
    localStorage.setItem(key, date.toISOString())


angular.module('onoSendai')
  .service 'localStorage', ->
    new LocalStorageUtil(arguments...)
