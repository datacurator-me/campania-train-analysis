# 🚆 Campania Regional Train Analysis

## Project Overview

This project analyzes public transport timetable data to explore scheduled train service intervals in Campania, Italy, using R.

The goal is to identify stations and routes with longer gaps between scheduled train arrivals and communicate the results through statistical summaries and visualizations.

This project is part of my Data Science portfolio and demonstrates data cleaning, exploratory data analysis, statistical analysis, data visualization, and reproducible research using R.

## 🎯 Research Questions

* Which stations have the longest average scheduled intervals between trains?
* How are scheduled train intervals distributed across stations?
* How does scheduled service frequency vary between routes?
* Which stations may deserve further investigation regarding service frequency?

## 📊 Dataset

**Source:** [Wimob Google Transit Data](https://www.wimob.it/cfile/download.php?file=google-transit.zip)

The dataset is expected to use the General Transit Feed Specification (GTFS), a standard format for public transport schedules.

Relevant files may include:

* `stops.txt` — station and stop information
* `stop_times.txt` — scheduled arrival and departure times
* `trips.txt` — scheduled trips
* `routes.txt` — route information
* `calendar.txt` and `calendar_dates.txt` — service operating dates

**Important:** The dataset's geographic coverage, transport operators, licence, and validity dates must be verified before drawing conclusions specifically about Campania's regional trains.

## 🛠️ Tools and Technologies

* **R** — data analysis
* **readr** — data import and export
* **dplyr** — data cleaning and transformation
* **ggplot2** — data visualization
* **GTFS** — public transport timetable format
* **Git and GitHub** — version control and project sharing

## 📁 Project Structure

```text
campania-train-analysis/
├── data/
│   └── raw/
│       └── README.md
├── scripts/
│   └── train_waiting_time.R
├── outputs/
│   ├── figures/
│   └── README.md
├── .gitignore
└── README.md
```

The raw GTFS ZIP file is not included in the repository by default. Save it locally as `data/google-transit.zip` (or `data/raw/google-transit.zip` if you prefer that layout).

## ⚙️ Installation and Setup

### 1. Install R

Download R from [CRAN](https://cran.r-project.org/).

### 2. Install the required packages

Open R or the VS Code terminal and run:

```r
install.packages(c("readr", "dplyr", "ggplot2"))
```

### 3. Download the dataset

Download the [Google Transit ZIP file](https://www.wimob.it/cfile/download.php?file=google-transit.zip) and save it as:

```text
data/raw/google-transit.zip
```

### 4. Run the analysis

From the project root directory, run:

```bash
Rscript scripts/train_waiting_time.R
```

The script attempts to select a service date based on the feed's calendar files. You can optionally specify a date:

```bash
SERVICE_DATE=2026-10-13 Rscript scripts/train_waiting_time.R
```

Use a date covered by the dataset's service calendar.

## 📈 Analysis and Outputs

The script is designed to generate:

* `scheduled_train_gaps.csv` — scheduled intervals between consecutive arrivals
* `station_summary.csv` — station-level mean, median, 90th-percentile, and maximum intervals
* `route_summary.csv` — route-level interval statistics
* `run_metadata.csv` — basic information about the analysis run

Visualizations are saved in `outputs/figures/`:

* `top_station_gaps.png` — stations with the highest mean scheduled intervals
* `interval_distribution.png` — distribution of scheduled intervals
* `top_route_gaps.png` — routes with the highest mean scheduled intervals

These outputs will be available after the script runs successfully.

## 📐 Methodology

1. Import the GTFS timetable files.
2. Select trips operating on a valid service date when calendar information is available.
3. Clean and transform scheduled arrival times.
4. Calculate intervals between consecutive scheduled arrivals at each stop, route, and direction.
5. Calculate descriptive statistics, including the mean, median, and 90th percentile.
6. Generate charts to explore differences in scheduled service intervals.
7. Export the results for further analysis.

Intervals longer than 240 minutes are excluded from the current summary. This is an analytical choice that should be reviewed during exploratory data analysis.

## ⚠️ Limitations

This project analyzes **scheduled service intervals**, not actual train delays.

GTFS timetable data alone cannot establish:

* Whether trains arrived late or were cancelled.
* How long passengers actually waited.
* Actual passenger satisfaction.
* Whether a scheduled service operated as planned.

These questions require additional operational records, historical delay data, or passenger survey results.

## 🚀 Future Improvements

* Verify the feed's geographic and operator coverage.
* Compare weekday and weekend service patterns.
* Analyze individual routes and directions.
* Add station maps and further visualizations.
* Incorporate official historical delay and cancellation data, if available.
* Compare timetable-based findings with passenger satisfaction survey results.

## 👤 Author

Created as a personal Data Science portfolio project to practice data analysis, statistical reasoning, visualization, and reproducible research using R.

## 📄 Data and Licensing

The dataset is linked to its original source. Please verify the applicable licence and attribution requirements before redistributing the data or derived materials.
