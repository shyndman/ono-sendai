#!/usr/bin/env python3

import urllib.request
import json

NRDB_URL = "http://netrunnerdb.com/api/cards/"
EXISTING_CARDS_PATH = 'app/data/cards.json'

def main():
  existing_cards_file = open(EXISTING_CARDS_PATH)
  existing_cards = json.load(existing_cards_file)
  existing_cards_file.close()

  nrdb_json = urllib.request.urlopen(NRDB_URL).readall().decode('utf-8') #unicode_escape'?
  nrdb_cards = json.loads(nrdb_json)
  
  #Remove Chronos Protocol cards
  cards_to_remove = []
  
  for i in range(len(existing_cards['cards'])):
    card = existing_cards['cards'][i]
    if 'Chronos Protocol' in card['title']:
      cards_to_remove.append(i)
      
  for i in cards_to_remove:
    del existing_cards['cards'][i]
  
  #Remove unused attributes from nrdb cards
  attr_to_remove = ['code','set_code','side_code','faction_code','cyclenumber','limited','faction_letter','type_code','subtype_code','last-modified']
  for card in nrdb_cards:
    for attr in attr_to_remove:
      del card[attr]
    
  print(nrdb_cards[0])
 
if __name__ == "__main__":
  main()