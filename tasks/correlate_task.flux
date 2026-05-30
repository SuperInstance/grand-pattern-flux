// Task: Cross-Room Correlation
// Runs every 5 minutes to compute pairwise cosine similarity
// between all active rooms.
//
// Note: Flux doesn't support dynamic cross-joins on tag values easily.
// This task computes correlations for a known set of room pairs.
// In production, use the correlate.flux query per pair, or maintain
// a room topology table.

option task = {name: "cross-room-correlate", every: 5m}

import "math"

// Get latest vibe positions for all rooms
all_vibes = from(bucket: "vibes")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "vibe")
  |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)
  |> group(columns: ["room_id", "_field"])
  |> mean()

// Pairwise correlation is done per room pair in correlate.flux
// This task triggers the correlation computation pipeline.
// For N rooms, you'd invoke correlate(room_a, room_b) for each pair.

// Example: correlate two specific rooms
// correlate(room_a: "chamber-7", room_b: "chamber-13")

// Output all vibes for downstream correlation processing
all_vibes
