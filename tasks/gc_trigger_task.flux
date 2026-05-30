// Task: GC Trigger
// Runs every hour to check if any room needs garbage collection.

option task = {name: "gc-trigger", every: 1h}

import "array"

// Count embeddings per room
counts = from(bucket: "perception_db")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "embedding")
  |> group(columns: ["room_id"])
  |> count()
  |> map(fn: (r) => ({r with needs_gc: if r._value > 10000 then true else false}))

// Filter rooms that need GC and write trigger
counts
  |> filter(fn: (r) => r.needs_gc == true)
  |> map(fn: (r) => ({
    _time: now(),
    _measurement: "gc_report",
    _field: "needs_gc",
    _value: r._value,
    room_id: r.room_id,
  }))
  |> to(bucket: "gc_reports")
