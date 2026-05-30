// Task: Murmur
// Runs every 2 minutes to broadcast vibe summaries between neighboring rooms.

option task = {name: "murmur-broadcast", every: 2m}

import "array"

// Get latest vibe per room
latest_vibes = from(bucket: "vibes")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "vibe")
  |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)
  |> group(columns: ["room_id", "_field"])
  |> last()

// In production, room topology (neighbor graph) determines routing.
// Here we write the latest vibes to murmurs for each known pair.
// The actual neighbor mapping would come from a config bucket or static table.

// Example: murmur from chamber-7 to its neighbors
// murmur(from_room: "chamber-7", to_room: "chamber-13")
// murmur(from_room: "chamber-7", to_room: "chamber-21")

// Output for inspection
latest_vibes
