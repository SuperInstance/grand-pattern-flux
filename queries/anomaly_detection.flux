// Anomaly Detection
// Detect anomalies by comparing current prediction error against
// a rolling baseline. Flags when error exceeds baseline * spike_factor.
//
// This uses JEPA Round 2 results: the prediction error from the
// joint embedding predictive architecture serves as the anomaly signal.
//
// Parameters:
//   room_id      — room to check
//   spike_factor — multiplier over baseline to trigger anomaly (default: 3.0)
//   baseline_window — window for baseline computation (default: -1h)

import "array"

anomaly_detection = (room_id, spike_factor=3.0, baseline_window=-1h) => {
  // Baseline: mean prediction error over the past hour
  baseline = from(bucket: "surprises")
    |> range(start: baseline_window)
    |> filter(fn: (r) => r._measurement == "surprise")
    |> filter(fn: (r) => r.room_id == room_id)
    |> filter(fn: (r) => r._field == "prediction_error")
    |> mean()
    |> rename(columns: {_value: "baseline_error"})

  // Current: latest prediction error
  current = from(bucket: "surprises")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "surprise")
    |> filter(fn: (r) => r.room_id == room_id)
    |> filter(fn: (r) => r._field == "prediction_error")
    |> last()
    |> rename(columns: {_value: "current_error"})

  // Join and check if current > baseline * spike_factor
  result = join(tables: {b: baseline, c: current}, on: ["room_id"])
    |> map(fn: (r) => ({r with
      spike_threshold: r.baseline_error * spike_factor,
      is_anomaly: if r.current_error > (r.baseline_error * spike_factor) then true else false,
      spike_factor: spike_factor,
    }))

  return result
}

// Fleet-wide anomaly scan — check all rooms
fleet_anomaly_scan = (spike_factor=3.0, baseline_window=-1h) => {
  baseline = from(bucket: "surprises")
    |> range(start: baseline_window)
    |> filter(fn: (r) => r._measurement == "surprise")
    |> filter(fn: (r) => r._field == "prediction_error")
    |> group(columns: ["room_id"])
    |> mean()

  current = from(bucket: "surprises")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "surprise")
    |> filter(fn: (r) => r._field == "prediction_error")
    |> group(columns: ["room_id"])
    |> last()

  join(tables: {b: baseline, c: current}, on: ["room_id"])
    |> map(fn: (r) => ({r with
      is_anomaly: if r._value_c > (r._value_b * spike_factor) then true else false,
    }))
    |> filter(fn: (r) => r.is_anomaly == true)
}
