Ono-Sendai
==========

Ono-Sendai is a companion application to [Fantasy Flight's](http://www.fantasyflightgames.com/) Living Card Game, [*Android: Netrunner*](http://www.fantasyflightgames.com/edge_minisite.asp?eidm=207).

View it online at http://onosendaicorp.com

Building instructions
---------------------
Requirements:
  node.js, bower

1. Clone the repo
1. Run `npm install`
1. Run `npm install -g bower`
1. Run `bower install`
1. Copy the images in dist/images/cards to app/images/cards
1. Run `grunt server`

The server should now be up at `http://localhost:9000`

Licensing
---------
All code is offered under a [copyleft license](https://github.com/shyndman/ono-sendai/blob/develop/LICENSE) (GPL v3). All card images and text are copyrighted by Fantasy Flight Publishing, Inc. Ono-Sendai is not affiliated with or approved by Fantasy Flight.
