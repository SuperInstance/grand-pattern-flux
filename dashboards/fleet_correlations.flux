// Dashboard: Fleet Correlation Heatmap
// All-pairs cosine similarity across the fleet.
// Visualize as a heatmap where x=room_a, y=room_b, color=cosine_sim.
//
// Note: Full all-pairs computation requires iterating over room pairs.
// This query fetches pre-computed correlations from the correlations bucket.

// Recent correlations
from(bucket: "correlations")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "correlation")
  |> filter(fn: (r) => r._field == "cosine_sim")
  |> group(columns: ["room_a", "room_b"])
  |> mean()
  |> group()

// Most correlated pairs (top 10)
top_correlated = from(bucket: "correlations")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "correlation")
  |> filter(fn: (r) => r._field == "cosine_sim")
  |> group(columns: ["room_a", "room_b"])
  |> mean()
  |> group()
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 10)

// Least correlated pairs (bottom 10)
least_correlated = from(bucket: "correlations")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "correlation")
  |> filter(fn: (r) => r._field == "cosine_sim")
  |> group(columns: ["room_a", "room_b"])
  |> mean()
  |> group()
  |> sort(columns: ["_value"], desc: false)
  |> limit(n: 10)

top_correlated
