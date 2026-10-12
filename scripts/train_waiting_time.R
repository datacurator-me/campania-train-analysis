
# Campania Regional Train Analysis
# Analyzes scheduled intervals between train arrivals.
# Note: scheduled intervals are not actual delays or actual waiting times.

# Install required packages once if needed:
# install.packages(c("readr", "dplyr", "ggplot2", "stringr"))

library(readr)
library(dplyr)
library(ggplot2)
library(stringr)

# Project paths
candidate_paths <- c(
  "data/raw/eav_gtfs.zip",
  "data/raw/google-transit.zip",
  "data/google-transit.zip"
)

gtfs_zip <- candidate_paths[file.exists(candidate_paths)][1]
output_dir <- "outputs/figures"

dir.create("outputs", showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Check that the official GTFS file exists
if (is.na(gtfs_zip)) {
  stop(
    "GTFS ZIP not found. Download the official GTFS dataset and save it as one of: ",
    paste(candidate_paths, collapse = ", ")
  )
}

# Read GTFS files directly from the ZIP
gtfs_files <- unzip(gtfs_zip, list = TRUE)$Name

read_gtfs <- function(filename) {
  match <- gtfs_files[basename(gtfs_files) == filename]

  if (length(match) == 0) {
    return(NULL)
  }

  temp_file <- tempfile(fileext = ".txt")
  unzip(gtfs_zip, files = match[1], exdir = dirname(temp_file))
  extracted <- file.path(dirname(temp_file), match[1])

  read_csv(extracted, show_col_types = FALSE)
}

stops <- read_gtfs("stops.txt")
stop_times <- read_gtfs("stop_times.txt")
trips <- read_gtfs("trips.txt")

if (is.null(stops) || is.null(stop_times) || is.null(trips)) {
  stop("The ZIP must contain stops.txt, stop_times.txt and trips.txt.")
}

# Parse GTFS times, including hours greater than 24
parse_gtfs_time <- function(x) {
  parts <- str_split_fixed(as.character(x), ":", 3)

  as.numeric(parts[, 1]) * 60 +
    as.numeric(parts[, 2]) +
    as.numeric(parts[, 3]) / 60
}

# Prepare scheduled arrivals
arrivals <- stop_times |>
  filter(!is.na(arrival_time), !is.na(stop_id)) |>
  mutate(
    arrival_min = parse_gtfs_time(arrival_time),
    stop_sequence = as.numeric(stop_sequence)
  ) |>
  filter(!is.na(arrival_min)) |>
  inner_join(
    trips |> select(trip_id, route_id, service_id),
    by = "trip_id"
  ) |>
  inner_join(
    stops |> select(stop_id, stop_name),
    by = "stop_id"
  )

# Calculate gaps between consecutive scheduled arrivals
# at each stop. This is a timetable-based measure.
scheduled_gaps <- arrivals |>
  arrange(stop_id, arrival_min, stop_sequence) |>
  group_by(stop_id, stop_name) |>
  mutate(
    next_arrival_min = lead(arrival_min),
    gap_min = next_arrival_min - arrival_min
  ) |>
  ungroup() |>
  filter(!is.na(gap_min), gap_min > 0, gap_min <= 240)

# Save detailed results
write_csv(
  scheduled_gaps,
  "outputs/scheduled_train_gaps.csv"
)

# Summary by station
station_summary <- scheduled_gaps |>
  group_by(stop_id, stop_name) |>
  summarise(
    number_of_gaps = n(),
    mean_gap_min = mean(gap_min),
    median_gap_min = median(gap_min),
    p90_gap_min = quantile(gap_min, 0.90),
    .groups = "drop"
  ) |>
  arrange(desc(mean_gap_min))

write_csv(
  station_summary,
  "outputs/station_summary.csv"
)

# Chart: stations with the highest average scheduled gaps
top_stations <- station_summary |>
  arrange(desc(mean_gap_min)) |>
  slice_head(n = 12)

p <- ggplot(
  top_stations,
  aes(x = reorder(stop_name, mean_gap_min), y = mean_gap_min)
) +
  geom_col(
    fill = "#2563eb",
    color = "#1e3a8a",
    width = 0.8
  ) +
  coord_flip() +
  scale_y_continuous(labels = function(x) paste0(x, " min")) +
  labs(
    title = "Stations with the Longest Scheduled Intervals",
    subtitle = "Average time between consecutive scheduled arrivals at each stop",
    caption = "Source: GTFS schedule data. This measures timetable gaps, not actual delays or waiting times.",
    x = "Station",
    y = "Average scheduled interval"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "#374151"),
    plot.caption = element_text(size = 9, color = "#6b7280", hjust = 0),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

ggsave(
  file.path(output_dir, "top_station_gaps.png"),
  plot = p,
  width = 10,
  height = 7,
  dpi = 300
)

# Distribution of scheduled intervals: useful to understand typical service spacing
interval_distribution <- scheduled_gaps |>
  filter(gap_min > 0)

p_hist <- ggplot(interval_distribution, aes(x = gap_min)) +
  geom_histogram(
    bins = 25,
    fill = "#0ea5e9",
    color = "#082f49",
    alpha = 0.85
  ) +
  labs(
    title = "Distribution of Scheduled Intervals",
    subtitle = "Typical timetable gap between consecutive arrivals",
    x = "Interval (minutes)",
    y = "Number of observations",
    caption = "Observations are filtered to positive interval values and exclude very long outliers."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "#374151"),
    plot.caption = element_text(size = 9, color = "#6b7280", hjust = 0),
    axis.title = element_text(face = "bold")
  )

ggsave(
  file.path(output_dir, "interval_distribution.png"),
  plot = p_hist,
  width = 10,
  height = 7,
  dpi = 300
)

print(head(station_summary, 10))
message("Analysis complete. Check the outputs/ folder.")