// Task: Vibe Compute
// Runs every second to compute vibe vectors for all active rooms.
// Position = centroid, Velocity = 1st derivative, Acceleration = 2nd derivative.

option task = {name: "vibe-compute", every: 1s}

// Discover active rooms from recent perceptions
active_rooms = from(bucket: "perception_db")
  |> range(start: -1m)
  |> filter(fn: (r) => r._measurement == "embedding")
  |> group(columns: ["room_id"])
  |> last()
  |> keep(columns: ["room_id"])

// For each room, compute vibe and write to vibes bucket
// (In practice, this would be parameterized per room via task arguments)
readings = from(bucket: "perception_db")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "embedding")
  |> filter(fn: (r) => r._field =~ /^d[0-7]$/)

position = readings
  |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
  |> map(fn: (r) => ({r with _field: "pos_${r._field}"}))

velocity = readings
  |> derivative(unit: 1s, nonNegative: false)
  |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
  |> map(fn: (r) => ({r with _field: "vel_${r._field}"}))

acceleration = readings
  |> derivative(unit: 1s, nonNegative: false)
  |> derivative(unit: 1s, nonNegative: false)
  |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
  |> map(fn: (r) => ({r with _field: "acc_${r._field}"}))

union(tables: [position, velocity, acceleration])
  |> set(key: "_measurement", value: "vibe")
  |> to(bucket: "vibes")
