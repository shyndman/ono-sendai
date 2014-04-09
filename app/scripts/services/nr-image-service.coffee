# A service responsible for loading images.
class ImageService

  constructor: (@$q) ->

  # Begins loading the image found at url, and returns the Image
  # object. The image object is decorated with an additional property
  # called onloadPromise, which resolves when the image finishes
  # loading.
  load: (url) ->
    d = @$q.defer()
    img = new Image(url)
    img.src = url
    img.onload = ->
      d.resolve(img)
    img.onloadPromise = d.promise
    img


angular.module('onoSendai')
  .service 'imageService', ($q) ->
    new ImageService(arguments...)
