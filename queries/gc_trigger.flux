// GC Trigger
// Detect when a room's embedding count exceeds a threshold,
// signalling the computation layer to run garbage collection
// (merge, decay, prune).
//
// Parameters:
//   room_id        — room to check
//   max_embeddings — threshold count (default: 10000)

import "array"

gc_trigger = (room_id, max_embeddings=10000) => {
  count = from(bucket: "perception_db")
    |> range(start: -30d)
    |> filter(fn: (r) => r._measurement == "embedding")
    |> filter(fn: (r) => r.room_id == room_id)
    |> group(columns: ["room_id"])
    |> count()
    |> map(fn: (r) => ({r with
      needs_gc: if r._value > max_embeddings then true else false,
      max_embeddings: max_embeddings,
    }))

  // If GC needed, write a trigger report placeholder
  // (actual merge/decay/prune counts are written by the computation layer)
  count
    |> filter(fn: (r) => r.needs_gc == true)
    |> map(fn: (r) => ({
      _time: now(),
      _measurement: "gc_report",
      room_id: room_id,
      merged_count: 0,
      decayed_count: 0,
      pruned_count: 0,
    }))
    |> array.from()
    |> to(bucket: "gc_reports")

  return count
}

// Check all rooms for GC
gc_check_all = (max_embeddings=10000) => {
  from(bucket: "perception_db")
    |> range(start: -30d)
    |> filter(fn: (r) => r._measurement == "embedding")
    |> group(columns: ["room_id"])
    |> count()
    |> map(fn: (r) => ({r with
      needs_gc: if r._value > max_embeddings then true else false,
      max_embeddings: max_embeddings,
    }))
}
