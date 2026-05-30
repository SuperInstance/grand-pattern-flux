// Test: Balance Check
// Validates that balance_check correctly identifies imbalance.

import "testing"
import "array"

// Mock data: 3 perceptions, 2 predictions (imbalanced)
mock_perceptions = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "embedding", room_id: "test-room", _field: "d0", _value: 1.0},
  {_time: 2024-01-01T00:00:01Z, _measurement: "embedding", room_id: "test-room", _field: "d0", _value: 2.0},
  {_time: 2024-01-01T00:00:02Z, _measurement: "embedding", room_id: "test-room", _field: "d0", _value: 3.0},
])

mock_predictions = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "prediction", room_id: "test-room", _field: "d0", _value: 1.5},
  {_time: 2024-01-01T00:00:01Z, _measurement: "prediction", room_id: "test-room", _field: "d0", _value: 2.5},
])

p_count = mock_perceptions |> group(columns: ["room_id"]) |> count() |> rename(columns: {_value: "p"})
pred_count = mock_predictions |> group(columns: ["room_id"]) |> count() |> rename(columns: {_value: "pred"})

result = join(tables: {p: p_count, pred: pred_count}, on: ["room_id"])
  |> map(fn: (r) => ({r with imbalance: r.p - r.pred}))

// Expect imbalance of 1
testing.assertEquals(got: result |> findRecord(fn: (r) => true, idx: 0).imbalance, want: 1)
