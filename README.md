#  Campania Regional Train Analysis

## Project Overview

This project analyzes scheduled rail-arrival intervals in EAV's Campania GTFS feed using R. The feed also contains bus services; the analysis filters those out.

The goal is to describe the spacing between scheduled train arrivals at each stop on a selected service date.

This project is part of my Data Science portfolio and demonstrates data cleaning, exploratory data analysis, statistical analysis, data visualization, and reproducible research using R.

##  Research Questions

* Which stations have the longest average scheduled intervals between trains?
* How are scheduled train intervals distributed across stations?
* Which stations may deserve further investigation regarding service frequency?

##  Dataset

**Source:** [Wimob Google Transit Data](https://www.wimob.it/cfile/download.php?file=google-transit.zip), a GTFS feed that identifies EAV rail and bus routes.

The dataset is expected to use the General Transit Feed Specification (GTFS), a standard format for public transport schedules.

Relevant files may include:

* `stops.txt` — station and stop information
* `stop_times.txt` — scheduled arrival and departure times
* `trips.txt` — scheduled trips
* `routes.txt` — route information
* `calendar.txt` and/or `calendar_dates.txt` — service operating dates

The analysis selects GTFS `route_type = 2` (rail) and only trips active on the chosen service date. Verify the feed's geographic coverage and licence before redistributing the source data or making broader claims about regional service.

##  Tools and Technologies

* **R** — data analysis
* **readr** — data import and export
* **dplyr** — data cleaning and transformation
* **ggplot2** — data visualization
* **GTFS** — public transport timetable format
* **Git and GitHub** — version control and project sharing

##  Project Structure

```text
campania-train-analysis/
├── data/
│   └── google-transit.zip
├── scripts/
│   └── train_waiting_time.R
├── outputs/
│   ├── scheduled_train_gaps.csv
│   ├── station_summary.csv
│   ├── run_metadata.csv
│   ├── figures/
│   └── ...
├── .gitignore
└── README.md
```

The GTFS archive is stored at `data/google-transit.zip`. The script also accepts `data/raw/google-transit.zip` and `data/raw/eav_gtfs.zip`.

##  Installation and Setup

### 1. Install R

Download R from [CRAN](https://cran.r-project.org/).

### 2. Install the required packages

Open R or the VS Code terminal and run:

```r
install.packages(c("readr", "dplyr", "ggplot2"))
```

### 3. Dataset

The repository includes the feed at `data/google-transit.zip`. To use a refreshed copy, download the [Google Transit ZIP file](https://www.wimob.it/cfile/download.php?file=google-transit.zip) and replace it there, or save it at one of the alternate paths supported by the script.

### 4. Run the analysis

From the project root directory, run:

```bash
Rscript scripts/train_waiting_time.R
```

By default, the script analyzes the current date. Set `SERVICE_DATE` to choose a different date covered by the feed:

```bash
SERVICE_DATE=2026-10-13 Rscript scripts/train_waiting_time.R
```

If no rail service is active on that date, the script stops with an error rather than combining schedules from different days.

##  Analysis and Outputs

The script is designed to generate:

* `scheduled_train_gaps.csv` — intervals between consecutive scheduled rail arrivals at each stop
* `station_summary.csv` — per-stop interval count, mean, median, 90th percentile, and maximum
* `run_metadata.csv` — selected service date and counts of active services, trips, arrivals, and intervals

Visualizations are saved in `outputs/figures/`:

* `top_station_gaps.png` — stops with the highest mean interval, limited to stops with at least five observed intervals
* `interval_distribution.png` — distribution of scheduled intervals for the selected date

These outputs will be available after the script runs successfully.

##  Methodology

1. Import GTFS timetable, route, stop, and service-calendar files.
2. Select rail trips active on the requested service date.
3. Parse GTFS arrival times, including times after midnight represented as hour values greater than 24.
4. Calculate intervals between consecutive arrivals at each stop for that service date.
5. Calculate descriptive statistics and generate charts.
6. Export the detailed intervals, station summaries, and run metadata.

All non-negative intervals are retained; the previous 240-minute cutoff is no longer applied. Arrivals at the same scheduled time yield a zero-minute interval. Intervals are not wrapped from the last arrival of the selected service day to the first arrival of the next day.

##  Limitations

This project analyzes **scheduled service intervals**, not actual train delays or passenger waiting times. Results describe one service date at a time and can vary by date.

GTFS timetable data alone cannot establish:

* Whether trains arrived late or were cancelled.
* How long passengers actually waited.
* Actual passenger satisfaction.
* Whether a scheduled service operated as planned.

These questions require additional operational records, historical delay data, or passenger survey results.

##  Future Improvements

* Verify the feed's geographic and operator coverage.
* Compare weekday and weekend service patterns.
* Analyze individual routes and directions.
* Add station maps and further visualizations.
* Incorporate official historical delay and cancellation data, if available.
* Compare timetable-based findings with passenger satisfaction survey results.

##  Author

Created as a personal Data Science portfolio project to practice data analysis, statistical reasoning, visualization, and reproducible research using R.

##  Data and Licensing

The GTFS archive is sourced from [Wimob](https://www.wimob.it/cfile/download.php?file=google-transit.zip). Please verify the applicable licence and attribution requirements before redistributing the source data or derived materials.
