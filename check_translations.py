#!/usr/bin/env python3
import json
import os

def load_translation_file(file_path):
    """Load a translation JSON file with path validation"""
    try:
        # Validate path to prevent traversal
        abs_path = os.path.abspath(file_path)
        project_root = os.path.abspath(os.path.dirname(__file__))
        
        if not abs_path.startswith(project_root):
            raise ValueError(f"Path traversal detected: {file_path}")
        
        with open(abs_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}

def check_translations():
    """Check for missing keys across all translation files"""
    translations_dir = "assets/translations"
    languages = ['en', 'fr', 'ar']
    
    # Load all translation files
    translations = {}
    for lang in languages:
        file_path = os.path.join(translations_dir, f"{lang}.json")
        translations[lang] = load_translation_file(file_path)
    
    # Get all unique keys
    all_keys = set()
    for lang_data in translations.values():
        all_keys.update(lang_data.keys())
    
    print(f"Total unique keys found: {len(all_keys)}")
    print("=" * 50)
    
    # Check for missing keys in each language
    missing_keys = {}
    for lang in languages:
        missing = all_keys - set(translations[lang].keys())
        if missing:
            missing_keys[lang] = sorted(missing)
    
    # Report missing keys
    if missing_keys:
        print("MISSING KEYS FOUND:")
        print("=" * 50)
        for lang, keys in missing_keys.items():
            print(f"\n{lang.upper()} missing {len(keys)} keys:")
            for key in keys:
                print(f"  - {key}")
    else:
        print("All languages have consistent keys!")
    
    # Check for duplicate keys (shouldn't happen in JSON but good to verify)
    print("\n" + "=" * 50)
    print("KEY COUNTS BY LANGUAGE:")
    for lang in languages:
        print(f"{lang.upper()}: {len(translations[lang])} keys")
    
    return len(missing_keys) == 0

if __name__ == "__main__":
    success = check_translations()
    exit(0 if success else 1)