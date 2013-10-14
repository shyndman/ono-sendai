_.mixin(_.str.exports()); # Make underscore.string functions available under the _ namespace

angular.module('deckBuilder', ['ui.bootstrap.buttons', 'ui.bootstrap.tooltip'])
  .config(->
    # Sidesteps the 300ms click event on mobile devices
    FastClick.attach(document.body))
