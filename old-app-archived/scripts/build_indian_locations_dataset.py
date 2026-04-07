import csv
import json
import re
import urllib.request
from pathlib import Path

PINCODE_CSV_URL = "https://raw.githubusercontent.com/dropdevrahul/pincodes-india/main/pincode.csv"
ROOT = Path(__file__).resolve().parents[1]
CACHE_DIR = ROOT / "scripts" / ".cache"
CACHE_DIR.mkdir(parents=True, exist_ok=True)
PINCODE_CSV_PATH = CACHE_DIR / "pincode.csv"
OUTPUT_PATH = ROOT / "TranZfort" / "assets" / "data" / "indian_locations.json"


def _title(text: str) -> str:
    cleaned = (text or "").strip()
    if not cleaned:
        return ""
    return re.sub(r"\s+", " ", cleaned).title()


def _clean_office_name(office: str) -> str:
    name = (office or "").strip()
    name = re.sub(r"\s+[BSH]\.O$", "", name)
    return name.strip()


def _to_float(value: str):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _download_if_needed() -> None:
    if PINCODE_CSV_PATH.exists() and PINCODE_CSV_PATH.stat().st_size > 1024:
        return
    print(f"Downloading pincode source from {PINCODE_CSV_URL}...")
    urllib.request.urlretrieve(PINCODE_CSV_URL, PINCODE_CSV_PATH)


def _postal_records():
    records = []
    seen = set()

    with PINCODE_CSV_PATH.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            state = _title(row.get("StateName", ""))
            district = _title(row.get("District", ""))
            office_raw = (row.get("OfficeName") or "").strip()
            office_clean = _clean_office_name(office_raw)
            office_type = (row.get("OfficeType") or "").strip().upper()
            pincode = (row.get("Pincode") or "").strip()
            lat = _to_float(row.get("Latitude", ""))
            lng = _to_float(row.get("Longitude", ""))

            if not office_clean or not state or lat is None or lng is None:
                continue

            place_type = "village" if office_type == "BO" else "post_office"
            key = (office_clean.lower(), state.lower(), district.lower(), pincode, place_type)
            if key in seen:
                continue
            seen.add(key)

            records.append(
                {
                    "city": office_clean,
                    "state": state,
                    "district": district,
                    "post": office_raw,
                    "village": office_clean if office_type == "BO" else "",
                    "pincode": pincode,
                    "lat": lat,
                    "lng": lng,
                    "place_type": place_type,
                    "postal_office_type": office_type,
                    "region": _title(row.get("RegionName", "")),
                    "division": _title(row.get("DivisionName", "")),
                    "circle": _title(row.get("CircleName", "")),
                    "source": "dropdevrahul/pincodes-india (data.gov.in)",
                    "source_url": PINCODE_CSV_URL,
                }
            )

    return records


def _curated_records():
    ports = [
        ("Deendayal Port", "Gujarat", "Kachchh", 22.9926, 70.2121),
        ("Mumbai Port", "Maharashtra", "Mumbai", 18.9497, 72.8406),
        ("Jawaharlal Nehru Port", "Maharashtra", "Raigad", 18.9422, 72.9519),
        ("Mormugao Port", "Goa", "South Goa", 15.4047, 73.8004),
        ("New Mangalore Port", "Karnataka", "Dakshina Kannada", 12.9272, 74.8120),
        ("Cochin Port", "Kerala", "Ernakulam", 9.9667, 76.2719),
        ("Chennai Port", "Tamil Nadu", "Chennai", 13.1060, 80.2933),
        ("Kamarajar Port", "Tamil Nadu", "Tiruvallur", 13.2410, 80.3160),
        ("V.O. Chidambaranar Port", "Tamil Nadu", "Thoothukudi", 8.7642, 78.1511),
        ("Visakhapatnam Port", "Andhra Pradesh", "Visakhapatnam", 17.6868, 83.2185),
        ("Paradip Port", "Odisha", "Jagatsinghpur", 20.2646, 86.6706),
        ("Kolkata Port", "West Bengal", "Kolkata", 22.5465, 88.3122),
        ("Syama Prasad Mookerjee Port Haldia", "West Bengal", "Purba Medinipur", 22.0553, 88.0698),
    ]

    industrial_hubs = [
        ("Bhiwandi Logistics Hub", "Maharashtra", "Thane", 19.2813, 73.0483),
        ("Taloja MIDC", "Maharashtra", "Raigad", 19.0776, 73.1286),
        ("Pithampur Industrial Area", "Madhya Pradesh", "Dhar", 22.6100, 75.6866),
        ("Sanand Industrial Estate", "Gujarat", "Ahmedabad", 22.9910, 72.3810),
        ("Vapi GIDC", "Gujarat", "Valsad", 20.3710, 72.9040),
        ("Ankleshwar GIDC", "Gujarat", "Bharuch", 21.6260, 73.0160),
        ("Noida Industrial Area", "Uttar Pradesh", "Gautam Buddha Nagar", 28.5355, 77.3910),
        ("Bawal Industrial Zone", "Haryana", "Rewari", 28.0800, 76.5830),
        ("Sri City", "Andhra Pradesh", "Tirupati", 13.6310, 79.9950),
        ("Oragadam Industrial Corridor", "Tamil Nadu", "Kanchipuram", 12.8400, 79.9600),
        ("Hosur Industrial Area", "Tamil Nadu", "Krishnagiri", 12.7409, 77.8253),
        ("Peenya Industrial Area", "Karnataka", "Bengaluru Urban", 13.0285, 77.5147),
        ("Mundra SEZ", "Gujarat", "Kachchh", 22.8390, 69.7210),
        ("Kandla SEZ", "Gujarat", "Kachchh", 23.0333, 70.2167),
    ]

    markets = [
        ("Azadpur Mandi", "Delhi", "North West Delhi", 28.7174, 77.1608),
        ("Vashi APMC", "Maharashtra", "Thane", 19.0785, 73.0176),
        ("Lasalgaon APMC", "Maharashtra", "Nashik", 20.1420, 74.2390),
        ("Koyambedu Market", "Tamil Nadu", "Chennai", 13.0682, 80.2059),
        ("Yeshwanthpur APMC", "Karnataka", "Bengaluru Urban", 13.0303, 77.5640),
        ("Bowenpally Market", "Telangana", "Hyderabad", 17.4747, 78.4874),
        ("Anaj Mandi Khanna", "Punjab", "Ludhiana", 30.7050, 76.2210),
        ("Khamgaon APMC", "Maharashtra", "Buldhana", 20.7075, 76.5686),
        ("Nizamabad Market Yard", "Telangana", "Nizamabad", 18.6725, 78.0941),
        ("Muzaffarnagar Mandi", "Uttar Pradesh", "Muzaffarnagar", 29.4727, 77.7085),
    ]

    factories = [
        ("Tata Steel Plant Jamshedpur", "Jharkhand", "East Singhbhum", 22.8046, 86.2029),
        ("Bhilai Steel Plant", "Chhattisgarh", "Durg", 21.1938, 81.3509),
        ("Rourkela Steel Plant", "Odisha", "Sundargarh", 22.2604, 84.8536),
        ("Bokaro Steel Plant", "Jharkhand", "Bokaro", 23.6693, 86.1511),
        ("Vizag Steel Plant", "Andhra Pradesh", "Visakhapatnam", 17.6700, 83.2100),
        ("Reliance Jamnagar Refinery", "Gujarat", "Jamnagar", 22.2758, 69.9572),
        ("Indian Oil Panipat Refinery", "Haryana", "Panipat", 29.3909, 76.9635),
        ("Chennai Petroleum Manali", "Tamil Nadu", "Chennai", 13.1644, 80.2871),
        ("Maruti Suzuki Manesar", "Haryana", "Gurugram", 28.3607, 76.9426),
        ("Hyundai Sriperumbudur", "Tamil Nadu", "Kanchipuram", 12.9700, 79.9500),
        ("Tata Motors Sanand", "Gujarat", "Ahmedabad", 22.9930, 72.3830),
        ("Hero MotoCorp Neemrana", "Rajasthan", "Alwar", 27.9910, 76.3780),
    ]

    records = []

    def add(name, state, district, lat, lng, place_type):
        records.append(
            {
                "city": name,
                "state": state,
                "district": district,
                "post": "",
                "village": "",
                "pincode": "",
                "lat": lat,
                "lng": lng,
                "place_type": place_type,
                "postal_office_type": "",
                "region": "",
                "division": "",
                "circle": "",
                "source": "Public logistics/industry references",
                "source_url": "https://opendata.upply.com/seaports",
            }
        )

    for row in ports:
        add(*row, "port")
    for row in industrial_hubs:
        add(*row, "industrial_hub")
    for row in markets:
        add(*row, "market")
    for row in factories:
        add(*row, "factory")

    return records


def main() -> None:
    _download_if_needed()
    postal = _postal_records()
    curated = _curated_records()

    merged = postal + curated
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, separators=(",", ":"))

    print(f"Wrote {len(merged)} records to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
