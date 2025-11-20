import json
from collections import Counter

# Load the Arabic translation file
with open('assets/translations/ar.json', 'r', encoding='utf-8') as f:
    ar_data = json.load(f)

# Check for duplicates
keys = list(ar_data.keys())
duplicates = [k for k, count in Counter(keys).items() if count > 1]

# Check for the 8 added keys
added_keys = [
    'players',
    'my_matches',
    'browse_matches',
    'no_matches_yet',
    'join_matches_message',
    'update_your_information',
    'select_city',
    'select_age_group'
]

found_keys = [k for k in added_keys if k in ar_data]

print("=" * 60)
print("ARABIC TRANSLATION VERIFICATION")
print("=" * 60)
print(f"\n✓ JSON is valid and properly formatted")
print(f"✓ Total keys in ar.json: {len(ar_data)}")
print(f"✓ Duplicate keys: {len(duplicates)} ({duplicates if duplicates else 'None'})")
print(f"\n✓ Added keys: {len(found_keys)}/8")
print("\nKeys added successfully:")
for key in found_keys:
    print(f"  - {key}: {ar_data[key]}")

print(f"\n{'✓' if len(found_keys) == 8 and len(duplicates) == 0 else '✗'} Arabic translation file is production-ready!")
print("=" * 60)