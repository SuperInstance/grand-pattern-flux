// Compute Vibe
// Calculate the vibe vector for a room:
//   position = centroid (mean) of embeddings over window
//   velocity = 1st derivative of position
//   acceleration = 2nd derivative of position
//
// Parameters:
//   room_id — target room
//   window  — aggregation window (default: 5m)

import "array"

compute_vibe = (room_id, window=5m) => {
  readings = from(bucket: "perception_db")
    |> range(start: -window)
    |> filter(fn: (r) => r._measurement == "embedding")
    |> filter(fn: (r) => r.room_id == room_id)

  // Position: centroid (mean) of each embedding dimension over window
  position = readings
    |> filter(fn: (r) => r._field =~ /^d[0-7]$/)
    |> aggregateWindow(every: window, fn: mean, createEmpty: false)
    |> map(fn: (r) => ({r with _field: "pos_${r._field}"}))

  // Velocity: first derivative of raw readings
  velocity = readings
    |> filter(fn: (r) => r._field =~ /^d[0-7]$/)
    |> derivative(unit: 1s, nonNegative: false)
    |> aggregateWindow(every: window, fn: mean, createEmpty: false)
    |> map(fn: (r) => ({r with _field: "vel_${string(v: r._field)}"}))

  // Acceleration: second derivative (derivative of velocity)
  acceleration = readings
    |> filter(fn: (r) => r._field =~ /^d[0-7]$/)
    |> derivative(unit: 1s, nonNegative: false)
    |> derivative(unit: 1s, nonNegative: false)
    |> aggregateWindow(every: window, fn: mean, createEmpty: false)
    |> map(fn: (r) => ({r with _field: "acc_${string(v: r._field)}"}))

  // Strength: aggregate signal strength over window
  strength = readings
    |> filter(fn: (r) => r._field == "strength")
    |> aggregateWindow(every: window, fn: mean, createEmpty: false)

  // Union all components and write to vibes bucket
  union(tables: [position, velocity, acceleration, strength])
    |> set(key: "_measurement", value: "vibe")
    |> set(key: "room_id", value: room_id)
    |> to(bucket: "vibes")

  return union(tables: [position, velocity, acceleration, strength])
    |> set(key: "_measurement", value: "vibe")
    |> set(key: "room_id", value: room_id)
}
