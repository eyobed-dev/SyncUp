import json

with open('assets/data/maps_data_merged.json') as f:
    d = json.load(f)

rooms = {k:v for r in d for k,v in r.items()}

for k, v in rooms.items():
    if 'extra' in k:
        coords = v.get('coords', [])
        print(f"{k}: {coords}")
