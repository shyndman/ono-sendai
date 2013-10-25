_.mixin(_.str.exports()); # Make underscore.string functions available under the _ namespace

angular.module('deckBuilder', ['ui.bootstrap.buttons', 'ui.bootstrap.tooltip'])
  .config ->
    # Prints a console welcome message
    titleColors = ['#000']
    fadeColors = ['#2D053D', '#440C59', '#60157C', '#79209D', '#9927BF']
    styles = _(titleColors)
      .chain()
      .concat(fadeColors)
      .map((c) -> "font-size: 10px; background: #{ c }; color: white; padding: 3px 1px;")
      .value()
    fade = _.repeat('%c ', fadeColors.length)

    console.log("%c ONO-SENDAI by scott hyndman#{ fade }", styles...)
    console.log('')

    # Sidesteps the 300ms click event on mobile devices
    FastClick.attach(document.body)
