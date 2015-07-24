#!/usr/bin/env python3

import urllib.request
import json
import re
import string

NRDB_URL = "http://netrunnerdb.com/api/cards/"
EXISTING_CARDS_PATH = 'app/data/cards.json'


def main():
    existing_cards_file = open(EXISTING_CARDS_PATH)
    existing_cards = json.load(existing_cards_file)
    existing_cards_file.close()

    nrdb_json = urllib.request.urlopen(NRDB_URL).readall().decode('utf-8')  # unicode_escape'?
    nrdb_cards = json.loads(nrdb_json)

    existing_cards['cards'] = remove_chronos_protocol(existing_cards['cards'])
    nrdb_cards = remove_chronos_protocol(nrdb_cards)

    # Remove unused attributes from nrdb cards
    attr_to_remove = ['code', 'set_code', 'side_code', 'faction_code', 'cyclenumber', 'limited', 'faction_letter',
                      'type_code', 'subtype_code', 'last-modified', 'url']
    for card in nrdb_cards:
        card['nrdb_url'] = card['url']
        card['nrdb_art'] = card['imagesrc']
        card['imagesrc'] = "/images/cards/" + image_name(card['title']) + ".png"
        for attr in attr_to_remove:
            del card[attr]

    print(nrdb_cards[0])


def remove_chronos_protocol(cards):
    cards_to_remove = []

    for i in range(len(cards)):
        card = cards[i]
        if 'Chronos Protocol' in card['title']:
            cards_to_remove.append(i)

    for i in cards_to_remove:
        del cards[i]

    return cards


#Make card titles friendly for filenames.
def image_name(title):
    title = title.replace(' ', '-')
    title = title.lower()
    #Replace all characters that aren't alphanumeric or -.
    title = re.sub('[^a-z0-9-]', '', title)

    return title


if __name__ == "__main__":
    main()
