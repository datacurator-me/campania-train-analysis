# Campania Regional Train Analysis
# Measures timetable intervals between scheduled rail arrivals at each stop.
# These are scheduled intervals, not actual delays or passenger waiting times.

# Install required packages once if needed:
# install.packages(c("readr", "dplyr", "ggplot2"))

library(readr)
library(dplyr)
library(ggplot2)

# Project paths
candidate_paths <- c(
  "data/google-transit.zip",
  "data/raw/google-transit.zip",
  "data/raw/eav_gtfs.zip"
)

gtfs_zip <- candidate_paths[file.exists(candidate_paths)][1]
output_dir <- "outputs/figures"

dir.create("outputs", showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (is.na(gtfs_zip)) {
  stop(
    "GTFS ZIP not found. Save the feed as one of: ",
    paste(candidate_paths, collapse = ", ")
  )
}

gtfs_files <- unzip(gtfs_zip, list = TRUE)$Name

read_gtfs <- function(filename, required = TRUE) {
  matches <- gtfs_files[basename(gtfs_files) == filename]

  if (length(matches) == 0) {
    if (required) {
      stop("Required GTFS file is missing: ", filename)
    }
    return(NULL)
  }

  temp_dir <- tempfile("gtfs-")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  unzip(gtfs_zip, files = matches[1], exdir = temp_dir)

  read_csv(
    file.path(temp_dir, matches[1]),
    col_types = cols(.default = col_character()),
    show_col_types = FALSE
  )
}

stops <- read_gtfs("stops.txt")
stop_times <- read_gtfs("stop_times.txt")
trips <- read_gtfs("trips.txt")
routes <- read_gtfs("routes.txt")
calendar <- read_gtfs("calendar.txt", required = FALSE)
calendar_dates <- read_gtfs("calendar_dates.txt", required = FALSE)

required_columns <- list(
  stops = c("stop_id", "stop_name"),
  stop_times = c("trip_id", "arrival_time", "stop_id", "stop_sequence"),
  trips = c("trip_id", "route_id", "service_id"),
  routes = c("route_id", "route_type")
)
gtfs_tables <- list(
  stops = stops,
  stop_times = stop_times,
  trips = trips,
  routes = routes
)

for (table_name in names(required_columns)) {
  missing_columns <- setdiff(
    required_columns[[table_name]],
    names(gtfs_tables[[table_name]])
  )
  if (length(missing_columns) > 0) {
    stop(
      table_name,
      ".txt is missing required column(s): ",
      paste(missing_columns, collapse = ", ")
    )
  }
}

if (is.null(calendar) && is.null(calendar_dates)) {
  stop("The GTFS feed must contain calendar.txt or calendar_dates.txt.")
}

rail_routes <- routes |>
  filter(route_type == "2")

if (nrow(rail_routes) == 0) {
  stop("No rail routes (GTFS route_type 2) were found in the feed.")
}

rail_trips <- trips |>
  inner_join(rail_routes, by = "route_id")

if (nrow(rail_trips) == 0) {
  stop("No trips were found for the feed's rail routes.")
}

service_date_text <- Sys.getenv("SERVICE_DATE", unset = format(Sys.Date()))
if (!grepl("^\\d{4}-\\d{2}-\\d{2}$", service_date_text)) {
  stop("SERVICE_DATE must use YYYY-MM-DD format; received: ", service_date_text)
}

service_date <- as.Date(service_date_text, format = "%Y-%m-%d")
if (is.na(service_date) || format(service_date, "%Y-%m-%d") != service_date_text) {
  stop("SERVICE_DATE is not a valid calendar date: ", service_date_text)
}

service_date_key <- format(service_date, "%Y%m%d")
active_services <- character()

if (!is.null(calendar)) {
  required_calendar_columns <- c(
    "service_id", "start_date", "end_date",
    "monday", "tuesday", "wednesday", "thursday",
    "friday", "saturday", "sunday"
  )
  missing_columns <- setdiff(required_calendar_columns, names(calendar))
  if (length(missing_columns) > 0) {
    stop(
      "calendar.txt is missing required column(s): ",
      paste(missing_columns, collapse = ", ")
    )
  }

  weekday_columns <- c(
    "sunday", "monday", "tuesday", "wednesday",
    "thursday", "friday", "saturday"
  )
  weekday_column <- weekday_columns[as.POSIXlt(service_date)$wday + 1]

  active_services <- calendar |>
    filter(
      start_date <= service_date_key,
      end_date >= service_date_key,
      .data[[weekday_column]] == "1"
    ) |>
    pull(service_id)
}

if (!is.null(calendar_dates)) {
  required_calendar_date_columns <- c("service_id", "date", "exception_type")
  missing_columns <- setdiff(required_calendar_date_columns, names(calendar_dates))
  if (length(missing_columns) > 0) {
    stop(
      "calendar_dates.txt is missing required column(s): ",
      paste(missing_columns, collapse = ", ")
    )
  }

  exceptions <- calendar_dates |>
    filter(date == service_date_key)

  active_services <- union(
    setdiff(active_services, exceptions$service_id[exceptions$exception_type == "2"]),
    exceptions$service_id[exceptions$exception_type == "1"]
  )
}

active_rail_services <- intersect(
  unique(active_services),
  unique(rail_trips$service_id)
)

if (length(active_rail_services) == 0) {
  stop(
    "No rail services are scheduled for ", service_date_text,
    ". Choose a date covered by the GTFS service calendar using SERVICE_DATE."
  )
}

scheduled_trips <- rail_trips |>
  filter(service_id %in% active_rail_services)

if (nrow(scheduled_trips) == 0) {
  stop("No rail trips are active on ", service_date_text, ".")
}

parse_gtfs_time <- function(x) {
  valid_time <- grepl("^[0-9]+:[0-5][0-9]:[0-5][0-9]$", x)
  invalid_time <- !is.na(x) & nzchar(x) & !valid_time

  if (any(invalid_time)) {
    examples <- unique(x[invalid_time])
    stop(
      "Invalid GTFS arrival_time value(s): ",
      paste(head(examples, 5), collapse = ", ")
    )
  }

  vapply(x, function(value) {
    if (is.na(value) || !nzchar(value)) {
      return(NA_real_)
    }
    parts <- as.numeric(strsplit(value, ":", fixed = TRUE)[[1]])
    parts[1] * 60 + parts[2] + parts[3] / 60
  }, numeric(1))
}

arrivals <- stop_times |>
  filter(
    !is.na(arrival_time),
    nzchar(arrival_time),
    !is.na(stop_id),
    nzchar(stop_id)
  ) |>
  inner_join(
    scheduled_trips |>
      select(trip_id, route_id, service_id, any_of("direction_id")),
    by = "trip_id"
  ) |>
  inner_join(
    stops |> select(stop_id, stop_name),
    by = "stop_id"
  ) |>
  mutate(
    arrival_min = parse_gtfs_time(arrival_time),
    stop_sequence = as.numeric(stop_sequence)
  ) |>
  filter(!is.na(arrival_min), !is.na(stop_sequence))

if (nrow(arrivals) < 2) {
  stop("Fewer than two rail arrivals were found for ", service_date_text, ".")
}

# Compare arrivals at each stop across all active rail trips. GTFS times above
# 24:00 remain on the selected service date; no overnight wraparound is added.
scheduled_gaps <- arrivals |>
  arrange(stop_id, arrival_min, route_id, stop_sequence, trip_id) |>
  group_by(stop_id, stop_name) |>
  mutate(
    next_arrival_min = lead(arrival_min),
    next_arrival_time = lead(arrival_time),
    next_trip_id = lead(trip_id),
    gap_min = next_arrival_min - arrival_min
  ) |>
  ungroup() |>
  filter(!is.na(gap_min), gap_min >= 0) |>
  select(
    stop_id, stop_name, arrival_time, next_arrival_time,
    trip_id, next_trip_id, route_id, service_id,
    any_of("direction_id"), gap_min
  )

if (nrow(scheduled_gaps) == 0) {
  stop("No consecutive rail-arrival intervals could be calculated.")
}

write_csv(scheduled_gaps, "outputs/scheduled_train_gaps.csv")

station_summary <- scheduled_gaps |>
  group_by(stop_id, stop_name) |>
  summarise(
    number_of_gaps = n(),
    mean_gap_min = mean(gap_min),
    median_gap_min = median(gap_min),
    p90_gap_min = unname(quantile(gap_min, 0.90)),
    max_gap_min = max(gap_min),
    .groups = "drop"
  ) |>
  arrange(desc(mean_gap_min))

write_csv(station_summary, "outputs/station_summary.csv")

run_metadata <- tibble(
  service_date = service_date_text,
  gtfs_file = gtfs_zip,
  route_type = "2 (rail)",
  active_rail_services = length(active_rail_services),
  scheduled_rail_trips = nrow(scheduled_trips),
  rail_arrivals = nrow(arrivals),
  scheduled_intervals = nrow(scheduled_gaps)
)
write_csv(run_metadata, "outputs/run_metadata.csv")

# Avoid ranking stations from only a handful of observed intervals.
top_stations <- station_summary |>
  filter(number_of_gaps >= 5) |>
  arrange(desc(mean_gap_min)) |>
  slice_head(n = 12)

if (nrow(top_stations) == 0) {
  stop(
    "No station has at least five intervals for the selected service date; ",
    "the station chart was not generated."
  )
}

station_plot <- ggplot(
  top_stations,
  aes(x = reorder(stop_name, mean_gap_min), y = mean_gap_min)
) +
  geom_col(fill = "#2563eb", color = "#1e3a8a", width = 0.8) +
  coord_flip() +
  scale_y_continuous(labels = function(x) paste0(x, " min")) +
  labs(
    title = "Rail Stops with the Longest Scheduled Intervals",
    subtitle = paste0(
      "Mean interval on ", service_date_text,
      "; only stops with at least five intervals shown"
    ),
    caption = paste(
      "Source: EAV GTFS timetable. Scheduled intervals are not actual delays",
      "or passenger waiting times."
    ),
    x = "Stop",
    y = "Mean scheduled interval"
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
  plot = station_plot,
  width = 10,
  height = 7,
  dpi = 300
)

interval_plot <- ggplot(scheduled_gaps, aes(x = gap_min)) +
  geom_histogram(
    bins = 25,
    fill = "#0ea5e9",
    color = "#082f49",
    alpha = 0.85
  ) +
  labs(
    title = "Distribution of Scheduled Rail Intervals",
    subtitle = paste("Intervals between arrivals on", service_date_text),
    x = "Interval (minutes)",
    y = "Number of intervals",
    caption = paste(
      "All non-negative intervals are included; overnight wraparound is not",
      "added. Scheduled intervals are not actual passenger waiting times."
    )
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
  plot = interval_plot,
  width = 10,
  height = 7,
  dpi = 300
)

print(run_metadata)
print(head(station_summary, 10))
message("Analysis complete. Check the outputs/ folder.")
