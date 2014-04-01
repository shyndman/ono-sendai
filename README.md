Ono-Sendai
==========

Ono-Sendai is a companion application to [Fantasy Flight's](http://www.fantasyflightgames.com/) Living Card Game, [*Android: Netrunner*](http://www.fantasyflightgames.com/edge_minisite.asp?eidm=207).

View it online at http://onosendaicorp.com

Building instructions
---------------------
Requirements:
  node.js, bower, grunt

1. Clone the repo
1. Install dependencies if necessary
    * `npm install -g bower`
    * `npm install -g grunt-cli`
1. `npm install`
1. `bower install`
1. `grunt server`

The server should now be up at `http://localhost:9000`

Production builds
-----------------
Run `grunt build`. Output is written to `./dist`.

Licensing
---------
All code is offered under a [copyleft license](https://github.com/shyndman/ono-sendai/blob/develop/LICENSE) (GPL v3). 

All card images and text are copyrighted by Fantasy Flight Publishing, Inc. Ono-Sendai is not affiliated with or approved by Fantasy Flight.
