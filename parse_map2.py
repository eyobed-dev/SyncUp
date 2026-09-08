# Authors:
#   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
#   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
#   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
#   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
#
# License: GPL
#
# Purpose: Parses legacy SVG and graph node data into JSON format for the map feature.

import json

with open('assets/data/maps_data_merged.json') as f:
    d = json.load(f)

rooms = {k:v for r in d for k,v in r.items()}

for k, v in rooms.items():
    if 'extra' in k:
        coords = v.get('coords', [])
        print(f"{k}: {coords}")
