// Cross-Room Correlation
// Compute cosine similarity between two rooms' vibe position vectors
// over a sliding window.
//
// Parameters:
//   room_a  — first room
//   room_b  — second room
//   window  — lookback window (default: 30m)
//
// Note: Flux doesn't have a native cosine similarity function.
// We approximate by computing the dot product and magnitudes
// from the position dimensions.

correlate = (room_a, room_b, window=30m) => {
  vibe_a = from(bucket: "vibes")
    |> range(start: -window)
    |> filter(fn: (r) => r._measurement == "vibe")
    |> filter(fn: (r) => r.room_id == room_a)
    |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)

  vibe_b = from(bucket: "vibes")
    |> range(start: -window)
    |> filter(fn: (r) => r._measurement == "vibe")
    |> filter(fn: (r) => r.room_id == room_b)
    |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)

  // Aggregate each room's position dimensions to a single mean per field
  agg_a = vibe_a
    |> group(columns: ["_field"])
    |> mean()
    |> rename(columns: {_value: "val_a"})

  agg_b = vibe_b
    |> group(columns: ["_field"])
    |> mean()
    |> rename(columns: {_value: "val_b"})

  // Join on _field (d0..d7) to compute dot product components
  joined = join(tables: {a: agg_a, b: agg_b}, on: ["_field"])

  // Dot product: sum of a_i * b_i
  dot = joined
    |> map(fn: (r) => ({r with product: r.val_a * r.val_b}))
    |> group()
    |> sum(column: "product")
    |> rename(columns: {product: "dot_product"})

  // Magnitude A: sqrt(sum of a_i^2)
  mag_a = agg_a
    |> map(fn: (r) => ({r with sq: r.val_a * r.val_a}))
    |> group()
    |> sum(column: "sq")
    |> map(fn: (r) => ({r with mag_a: math.sqrt(x: r.sq)}))

  // Magnitude B: sqrt(sum of b_i^2)
  mag_b = agg_b
    |> map(fn: (r) => ({r with sq: r.val_b * r.val_b}))
    |> group()
    |> sum(column: "sq")
    |> map(fn: (r) => ({r with mag_b: math.sqrt(x: r.sq)}))

  // Cosine similarity = dot / (mag_a * mag_b)
  mags = join(tables: {a: mag_a, b: mag_b}, on: [])
  result = join(tables: {d: dot, m: mags}, on: [])
    |> map(fn: (r) => ({r with cosine_sim: r.dot_product / (r.mag_a * r.mag_b)}))
    |> map(fn: (r) => ({
      _time: now(),
      _measurement: "correlation",
      room_a: room_a,
      room_b: room_b,
      cosine_sim: r.cosine_sim,
    }))
    |> to(bucket: "correlations")

  return result
}

import "math"
