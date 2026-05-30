// Dashboard: Vibe Trajectory
// Position over time for a room — shows how the room's embedding centroid
// moves through the latent space.
//
// Use: Change room_id to visualize different rooms.

room_id = "chamber-7"

// Position trajectory
from(bucket: "vibes")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "vibe")
  |> filter(fn: (r) => r.room_id == room_id)
  |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)

// Velocity trajectory
velocity = from(bucket: "vibes")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "vibe")
  |> filter(fn: (r) => r.room_id == room_id)
  |> filter(fn: (r) => r._field =~ /^vel_d[0-7]$/)

// Acceleration trajectory
acceleration = from(bucket: "vibes")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "vibe")
  |> filter(fn: (r) => r.room_id == room_id)
  |> filter(fn: (r) => r._field =~ /^acc_d[0-7]$/)

// Combined timeline
union(tables: [
  from(bucket: "vibes")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "vibe")
    |> filter(fn: (r) => r.room_id == room_id)
    |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)
    |> map(fn: (r) => ({r with component: "position"})),
  from(bucket: "vibes")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "vibe")
    |> filter(fn: (r) => r.room_id == room_id)
    |> filter(fn: (r) => r._field =~ /^vel_d[0-7]$/)
    |> map(fn: (r) => ({r with component: "velocity"})),
  from(bucket: "vibes")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "vibe")
    |> filter(fn: (r) => r.room_id == room_id)
    |> filter(fn: (r) => r._field =~ /^acc_d[0-7]$/)
    |> map(fn: (r) => ({r with component: "acceleration"})),
])
