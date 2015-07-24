#!/usr/bin/env python3

import urllib.request
import json
import re
from wand.image import Image
#from wand.api import library
import ctypes

NRDB_URL = "http://netrunnerdb.com/api/cards/"
EXISTING_CARDS_PATH = 'app/data/cards.json'

# Register C-type arguments
#library.MagickQuantizeImage.argtypes = [ctypes.c_void_p,
#                                        ctypes.c_size_t,
#                                        ctypes.c_int,
#                                        ctypes.c_size_t,
#                                        ctypes.c_int,
#                                        ctypes.c_int
#                                       ]   
#library.MagickQuantizeImage.restype = None

def main():
    existing_cards_file = open(EXISTING_CARDS_PATH, encoding='utf-8')
    existing_cards = json.load(existing_cards_file)
    existing_cards_file.close()

    nrdb_json = urllib.request.urlopen(NRDB_URL).readall().decode('utf-8')  # unicode_escape'?
    nrdb_cards = json.loads(nrdb_json)

    # Remove the Chronos Protocol cards
    existing_cards['cards'] = remove_chronos_protocol(existing_cards['cards'])
    nrdb_cards = remove_chronos_protocol(nrdb_cards)

    # Remove the following unused attributes from nrdb cards
    attr_to_remove = ['code', 'set_code', 'side_code', 'faction_code', 'cyclenumber', 'limited', 'faction_letter',
                      'type_code', 'subtype_code', 'last-modified', 'url']

    for card in nrdb_cards:
        card['nrdb_url'] = card['url']
        card['nrdb_art'] = card['imagesrc']
        card['imagesrc'] = "/images/cards/" + image_name(card['title']) + ".png"
        for attr in attr_to_remove:
            del card[attr]

        save_card_image(card['nrdb_art'], card['imagesrc'])

        del card['nrdb_art']

    print(nrdb_cards[0])
    
def save_card_image(url_to_card, path_to_save):
    image_response = urllib.request.urlopen('http://netrunnerdb.com/' + url_to_card)
    try:
        with Image(file=image_response, format='png') as img:
            # Update the image settings
            #color_count = 256
            #colorspace = 1 # RGB
            #treedepth = 8                
            #dither = 1 # True
            #merror = 0 # False
            #library.MagickQuantizeImage(img.wand,color_count,colorspace,treedepth,dither,merror)
            
            # Save the new image
            img.save(filename='app' + path_to_save)
            print("Saving - app" + path_to_save)
    finally:
        image_response.close()


def remove_chronos_protocol(cards):
    cards_to_remove = []

    for i in range(len(cards)):
        card = cards[i]
        if 'Chronos Protocol' in card['title']:
            cards_to_remove.append(i)

    for i in cards_to_remove:
        del cards[i]

    return cards


# Make card titles friendly for file names.
def image_name(title):
    title = title.replace(' ', '-')
    title = title.lower()
    # Replace all characters that aren't alphanumeric or -.
    title = re.sub('[^a-z0-9-]', '', title)

    return title


if __name__ == "__main__":
    main()
