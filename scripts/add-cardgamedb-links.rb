# Adds cardgame db links to cards.json

require 'json'

cgdb_card_urls = {}

open '../app/data/cardgamedb-cards.json' do |io|
  cards = JSON.load io
  cards.each do |card|
    cgdb_card_urls[card['name']] = card['furl']
  end
end

cards = nil
open '../app/data/cards.json' do |io|
  cards = JSON.load io
end

cards.each do |c|
  c['cgdb_url'] = cgdb_card_urls[c['title']]
end

open '../app/data/cards.json', 'w' do |io|
  io.write cards.to_json
end
