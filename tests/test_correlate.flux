// Test: Cross-Room Correlation
// Validates cosine similarity computation between two rooms.

import "testing"
import "array"
import "math"

// Mock vibe positions for two rooms
// Room A: d0=1.0, d1=0.0  → vector [1, 0]
// Room B: d0=0.0, d1=1.0  → vector [0, 1]
// Expected cosine similarity = 0.0 (orthogonal)

vibe_a = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-a", _field: "pos_d0", _value: 1.0},
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-a", _field: "pos_d1", _value: 0.0},
])

vibe_b = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-b", _field: "pos_d0", _value: 0.0},
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-b", _field: "pos_d1", _value: 1.0},
])

// Dot product
dot = join(tables: {a: vibe_a, b: vibe_b}, on: ["_field"])
  |> map(fn: (r) => ({r with product: r._value_a * r._value_b}))
  |> group()
  |> sum(column: "product")

// Magnitudes
mag_a = vibe_a
  |> map(fn: (r) => ({r with sq: r._value * r._value}))
  |> group()
  |> sum(column: "sq")
  |> map(fn: (r) => ({r with mag: math.sqrt(x: r.sq)}))

mag_b = vibe_b
  |> map(fn: (r) => ({r with sq: r._value * r._value}))
  |> group()
  |> sum(column: "sq")
  |> map(fn: (r) => ({r with mag: math.sqrt(x: r.sq)}))

// Cosine similarity
mags = join(tables: {a: mag_a, b: mag_b}, on: [])
result = join(tables: {d: dot, m: mags}, on: [])
  |> map(fn: (r) => ({r with cosine_sim: r.product / (r.mag_a * r.mag_b)}))

// Orthogonal vectors should have cosine similarity ≈ 0.0
testing.assertAlmostEqual(
  got: result |> findRecord(fn: (r) => true, idx: 0).cosine_sim,
  want: 0.0,
  tol: 0.001,
)

// Test parallel vectors: [1, 1] vs [1, 1] → cosine = 1.0
parallel_a = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-a", _field: "pos_d0", _value: 1.0},
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-a", _field: "pos_d1", _value: 1.0},
])

parallel_b = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-b", _field: "pos_d0", _value: 1.0},
  {_time: 2024-01-01T00:00:00Z, _measurement: "vibe", room_id: "room-b", _field: "pos_d1", _value: 1.0},
])

dot2 = join(tables: {a: parallel_a, b: parallel_b}, on: ["_field"])
  |> map(fn: (r) => ({r with product: r._value_a * r._value_b}))
  |> group()
  |> sum(column: "product")

mag_a2 = parallel_a |> map(fn: (r) => ({r with sq: r._value * r._value})) |> group() |> sum(column: "sq") |> map(fn: (r) => ({r with mag: math.sqrt(x: r.sq)}))
mag_b2 = parallel_b |> map(fn: (r) => ({r with sq: r._value * r._value})) |> group() |> sum(column: "sq") |> map(fn: (r) => ({r with mag: math.sqrt(x: r.sq)}))
mags2 = join(tables: {a: mag_a2, b: mag_b2}, on: [])
result2 = join(tables: {d: dot2, m: mags2}, on: []) |> map(fn: (r) => ({r with cosine_sim: r.product / (r.mag_a * r.mag_b)}))

testing.assertAlmostEqual(
  got: result2 |> findRecord(fn: (r) => true, idx: 0).cosine_sim,
  want: 1.0,
  tol: 0.001,
)
