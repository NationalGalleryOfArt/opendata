import pandas as pd
import requests
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock

DEFAULT_SAVE_FOLDER = os.path.join(os.getcwd(), "NGA_Dataset")
os.makedirs(DEFAULT_SAVE_FOLDER, exist_ok=True)
log_file = os.path.join(DEFAULT_SAVE_FOLDER, "download_log.txt")
log_lock = Lock()  # To prevent race conditions in logging

# Logging function (thread-safe)
def write_log(message):
    with log_lock:
        with open(log_file, "a") as log:
            log.write(message + "\n")

# Download function (run in parallel)
def download_image(row):
    base_url = row["iiifurl"]
    uuid = row["uuid"]
    image_url = f"{base_url}/full/full/360/default.jpg" # few images are partially returned if 360 is replaced with a zero
    file_name = f"{uuid}.jpg"
    file_path = os.path.join(DEFAULT_SAVE_FOLDER, file_name)

    try:
        response = requests.get(image_url, stream=True, timeout=15)

        if response.status_code == 200:
            with open(file_path, "wb") as file:
                for chunk in response.iter_content(1024):
                    if chunk:
                        file.write(chunk)
            print(f"Downloaded: {file_name}")
            write_log(f"SUCCESS: {file_name} | URL: {image_url}")
        else:
            print(f"FAILED (HTTP {response.status_code}): {file_name}")
            write_log(f"FAILURE (HTTP {response.status_code}): {file_name} | URL: {image_url}")

    except Exception as e:
        print(f"ERROR: {file_name} | {e}")
        write_log(f"ERROR: {file_name} | URL: {image_url} | Exception: {e}")

def download_dataset(csv_path, max_threads=8):
    data = pd.read_csv(csv_path)
    data = data.dropna(subset=["iiifurl"])

    write_log("=" * 60)
    write_log("New Download Session Started")
    write_log("=" * 60)

    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        futures = [executor.submit(download_image, row) for _, row in data.iterrows()]
        for future in as_completed(futures):
            pass  # We don't need to gather results, everything is logged inside threads

    print("Download complete!")

if __name__ == "__main__":
    csv_path = input("Enter the path to published_images.csv: ").strip()
    download_dataset(csv_path)
