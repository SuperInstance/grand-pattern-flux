// Test: GC Trigger
// Validates that GC is flagged when embedding count exceeds threshold.

import "testing"
import "array"

// Mock: 15 embeddings (threshold: 10)
mock_count = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "embedding", room_id: "test-room", _field: "count", _value: 15},
])

max_embeddings = 10

result = mock_count
  |> map(fn: (r) => ({r with
    needs_gc: if r._value > max_embeddings then true else false,
    max_embeddings: max_embeddings,
  }))

// Should flag GC needed
testing.assertEquals(
  got: result |> findRecord(fn: (r) => true, idx: 0).needs_gc,
  want: true,
)

// Mock: 5 embeddings (below threshold)
mock_count_safe = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "embedding", room_id: "test-room", _field: "count", _value: 5},
])

result_safe = mock_count_safe
  |> map(fn: (r) => ({r with
    needs_gc: if r._value > max_embeddings then true else false,
  }))

// Should NOT flag GC
testing.assertEquals(
  got: result_safe |> findRecord(fn: (r) => true, idx: 0).needs_gc,
  want: false,
)
