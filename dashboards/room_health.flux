// Dashboard: Room Health
// Assets (embeddings) vs Liabilities (anomalies) per room.
// Provides a quick health overview of the entire fleet.

import "influxdata/influxdb/schema"

// Total embeddings per room (assets)
assets = from(bucket: "perception_db")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "embedding")
  |> group(columns: ["room_id"])
  |> count()
  |> rename(columns: {_value: "embeddings"})

// Surprise count per room (liabilities)
liabilities = from(bucket: "surprises")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "surprise")
  |> group(columns: ["room_id"])
  |> count()
  |> rename(columns: {_value: "surprises"})

// GC reports per room (maintenance activity)
gc_activity = from(bucket: "gc_reports")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "gc_report")
  |> group(columns: ["room_id"])
  |> count()
  |> rename(columns: {_value: "gc_runs"})

// Join into health table
health = join(tables: {a: assets, l: liabilities}, on: ["room_id"])
  |> map(fn: (r) => ({r with health_ratio: float(v: r.embeddings) / float(v: r.surprises)}))

// Display
health
  |> group()
  |> sort(columns: ["health_ratio"], desc: true)
