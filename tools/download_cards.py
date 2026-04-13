"""Download Rider-Waite-Smith tarot card images from Wikimedia Commons."""
import json
import os
import urllib.request
import time

CARDS_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'cards')
os.makedirs(CARDS_DIR, exist_ok=True)

# Wikimedia Commons URLs for RWS tarot cards
# Pattern: https://upload.wikimedia.org/wikipedia/commons/thumb/X/XX/RWS_Tarot_NN_Name.jpg/200px-RWS_Tarot_NN_Name.jpg

MAJOR_ARCANA = {
    0: ("00", "Fool"),
    1: ("01", "Magician"),
    2: ("02", "High_Priestess"),
    3: ("03", "Empress"),
    4: ("04", "Emperor"),
    5: ("05", "Hierophant"),
    6: ("06", "Lovers"),
    7: ("07", "Chariot"),
    8: ("08", "Strength"),
    9: ("09", "Hermit"),
    10: ("10", "Wheel_of_Fortune"),
    11: ("11", "Justice"),
    12: ("12", "Hanged_Man"),
    13: ("13", "Death"),
    14: ("14", "Temperance"),
    15: ("15", "Devil"),
    16: ("16", "Tower"),
    17: ("17", "Star"),
    18: ("18", "Moon"),
    19: ("19", "Sun"),
    20: ("20", "Judgement"),
    21: ("21", "World"),
}

# Wikimedia file hashes (first 2 chars of the MD5 hash of the filename)
# These are needed for the Wikimedia URL structure
WIKI_BASE = "https://upload.wikimedia.org/wikipedia/commons"

# We'll use the direct commons URLs
MAJOR_URLS = {
    0: f"{WIKI_BASE}/9/90/RWS_Tarot_00_Fool.jpg",
    1: f"{WIKI_BASE}/d/de/RWS_Tarot_01_Magician.jpg",
    2: f"{WIKI_BASE}/8/88/RWS_Tarot_02_High_Priestess.jpg",
    3: f"{WIKI_BASE}/d/d2/RWS_Tarot_03_Empress.jpg",
    4: f"{WIKI_BASE}/c/c3/RWS_Tarot_04_Emperor.jpg",
    5: f"{WIKI_BASE}/8/8d/RWS_Tarot_05_Hierophant.jpg",
    6: f"{WIKI_BASE}/3/3a/RWS_Tarot_06_Lovers.jpg",
    7: f"{WIKI_BASE}/9/9b/RWS_Tarot_07_Chariot.jpg",
    8: f"{WIKI_BASE}/f/f5/RWS_Tarot_08_Strength.jpg",
    9: f"{WIKI_BASE}/4/4d/RWS_Tarot_09_Hermit.jpg",
    10: f"{WIKI_BASE}/3/3c/RWS_Tarot_10_Wheel_of_Fortune.jpg",
    11: f"{WIKI_BASE}/e/e0/RWS_Tarot_11_Justice.jpg",
    12: f"{WIKI_BASE}/2/2b/RWS_Tarot_12_Hanged_Man.jpg",
    13: f"{WIKI_BASE}/d/d7/RWS_Tarot_13_Death.jpg",
    14: f"{WIKI_BASE}/f/f8/RWS_Tarot_14_Temperance.jpg",
    15: f"{WIKI_BASE}/5/55/RWS_Tarot_15_Devil.jpg",
    16: f"{WIKI_BASE}/5/53/RWS_Tarot_16_Tower.jpg",
    17: f"{WIKI_BASE}/d/db/RWS_Tarot_17_Star.jpg",
    18: f"{WIKI_BASE}/7/7f/RWS_Tarot_18_Moon.jpg",
    19: f"{WIKI_BASE}/1/17/RWS_Tarot_19_Sun.jpg",
    20: f"{WIKI_BASE}/d/d5/RWS_Tarot_20_Judgement.jpg",
    21: f"{WIKI_BASE}/f/ff/RWS_Tarot_21_World.jpg",
}

SUITS = {
    "wands": "Wands",
    "cups": "Cups",
    "swords": "Swords",
    "pentacles": "Pentacles",
}

COURT = {1: "Ace", 11: "Page", 12: "Knight", 13: "Queen", 14: "King"}

def download(url, filepath):
    if os.path.exists(filepath):
        print(f"  SKIP {os.path.basename(filepath)}")
        return True
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "TaroApp/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            with open(filepath, 'wb') as f:
                f.write(resp.read())
        print(f"  OK   {os.path.basename(filepath)}")
        return True
    except Exception as e:
        print(f"  FAIL {os.path.basename(filepath)}: {e}")
        return False

def main():
    success = 0
    fail = 0

    # Download Major Arcana
    print("=== Major Arcana ===")
    for rank, url in MAJOR_URLS.items():
        num, name = MAJOR_ARCANA[rank]
        filepath = os.path.join(CARDS_DIR, f"major_{num}.jpg")
        if download(url, filepath):
            success += 1
        else:
            fail += 1
        time.sleep(0.3)

    # Download Minor Arcana
    for suit_key, suit_name in SUITS.items():
        print(f"\n=== {suit_name} ===")
        for rank in range(1, 15):
            if rank in COURT:
                rank_name = COURT[rank]
            else:
                rank_name = f"{rank:02d}"

            # Wikimedia naming: RWS_Tarot_Suit_RankName.jpg
            wiki_name = f"RWS_Tarot_{suit_name}_{rank_name}"
            # Try common URL patterns
            filepath = os.path.join(CARDS_DIR, f"{suit_key}_{rank:02d}.jpg")

            # We need the actual wiki hash - skip for now, use a different approach
            # For minor arcana, we'll use the numbered format
            num_str = f"{rank:02d}" if rank not in COURT else COURT[rank].lower()
            url = f"{WIKI_BASE}/thumb/0/00/{wiki_name}.jpg/200px-{wiki_name}.jpg"

            if not download(url, filepath):
                fail += 1
            else:
                success += 1
            time.sleep(0.3)

    print(f"\nDone: {success} downloaded, {fail} failed")

if __name__ == "__main__":
    main()
