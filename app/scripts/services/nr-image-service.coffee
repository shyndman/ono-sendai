# A service responsible for loading images.
class ImageService

  constructor: (@$q, @$document) ->

  # Begins loading the image found at url, and returns the Image
  # object. The image object is decorated with an additional property
  # called loadedPromise, which resolves when the image finishes
  # loading.
  load: (url) ->
    d = @$q.defer()
    img = @$document.get(0).createElement('img')
    img.src = url
    img.onload = ->
      d.resolve(img)
    img.loadedPromise = d.promise
    new ImageWrapper(img)

# Wraps a DOM node, and exposes a promise that is resolved when the
class ImageWrapper

  constructor: (imageEle) ->
    @getImageElement = -> imageEle

  loaded: ->
    @getImage().loadedPromise


angular.module('onoSendai')
  .service 'imageService', ($q, $document) ->
    new ImageService(arguments...)
