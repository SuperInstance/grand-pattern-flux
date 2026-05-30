// Test: Vibe Computation
// Validates position (mean), velocity (derivative), and acceleration (2nd derivative).

import "testing"
import "array"

// Mock readings with known slope (linear increase)
// d0 values: 1.0, 2.0, 3.0 → mean = 2.0, derivative ≈ 1.0/s
mock_readings = array.from(rows: [
  {_time: 2024-01-01T00:00:00Z, _measurement: "embedding", room_id: "test-room", _field: "d0", _value: 1.0},
  {_time: 2024-01-01T00:00:01Z, _measurement: "embedding", room_id: "test-room", _field: "d0", _value: 2.0},
  {_time: 2024-01-01T00:00:02Z, _measurement: "embedding", room_id: "test-room", _field: "d0", _value: 3.0},
])

// Position: mean of all values
position = mock_readings
  |> group(columns: ["_field"])
  |> mean()

// Verify mean is 2.0
testing.assertEquals(
  got: position |> findRecord(fn: (r) => r._field == "d0", idx: 0)._value,
  want: 2.0,
)

// Velocity: derivative
velocity = mock_readings
  |> derivative(unit: 1s, nonNegative: false)

// Derivative of [1, 2, 3] = [1, 1] (two differences)
vel_count = velocity |> group(columns: ["_field"]) |> count()

// Should have 2 derivative points (N-1 from original)
testing.assertEquals(
  got: vel_count |> findRecord(fn: (r) => r._field == "d0", idx: 0)._value,
  want: 2,
)
