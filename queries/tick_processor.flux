// Tick Processor
// Ingest a sensor reading into perception_db, generate a rolling prediction,
// compute prediction error, and flag surprises.
//
// Parameters:
//   room_id      — target room
//   sensor_id    — source sensor
//   embedding    — {d0..d7, strength} reading
//   prediction_n — window size for rolling average (default: 10)
//   surprise_threshold — error threshold to flag surprise (default: 0.5)

import "array"
import "math"

tick_processor = (room_id, sensor_id, reading, prediction_n=10, surprise_threshold=0.5) => {
  // 1. Write perception
  perception_write = array.from(rows: [{
    _time: now(),
    _measurement: "embedding",
    room_id: room_id,
    sensor_id: sensor_id,
    d0: reading.d0,
    d1: reading.d1,
    d2: reading.d2,
    d3: reading.d3,
    d4: reading.d4,
    d5: reading.d5,
    d6: reading.d6,
    d7: reading.d7,
    strength: reading.strength,
  }])
  |> to(bucket: "perception_db")

  // 2. Generate prediction: rolling mean of last N embeddings
  recent = from(bucket: "perception_db")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "embedding")
    |> filter(fn: (r) => r.room_id == room_id)
    |> filter(fn: (r) => r._field =~ /^d[0-7]$/)
    |> aggregateWindow(every: 1s, fn: mean, createEmpty: false)
    |> limit(n: prediction_n)
    |> group(columns: ["_field"])
    |> mean()
    |> set(key: "_measurement", value: "prediction")
    |> set(key: "room_id", value: room_id)
    |> to(bucket: "prediction_db")

  // 3. Compute prediction error (L2 norm of difference)
  prediction_vec = from(bucket: "prediction_db")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "prediction")
    |> filter(fn: (r) => r.room_id == room_id)
    |> last()

  actual_vec = from(bucket: "perception_db")
    |> range(start: -1m)
    |> filter(fn: (r) => r._measurement == "embedding")
    |> filter(fn: (r) => r.room_id == room_id)
    |> last()

  // Error = |prediction - actual| aggregated across dimensions
  error_join = join(tables: {pred: prediction_vec, act: actual_vec}, on: ["_field", "_time"], method: "inner")
  error = error_join
    |> map(fn: (r) => ({r with _value: math.abs(x: r._value_pred - r._value_act)}))
    |> group()
    |> sum()

  // 4. Flag surprise if error exceeds threshold
  surprise_flag = error
    |> map(fn: (r) => ({r with
      _measurement: "surprise",
      prediction_error: r._value,
      threshold: surprise_threshold,
      room_id: room_id,
    }))
    |> filter(fn: (r) => r.prediction_error > r.threshold)
    |> to(bucket: "surprises")

  return perception_write
}

// Batch tick processor — process a table of readings at once
batch_tick = (tables=<-) => {
  // Store all rows to perception_db
  tables
    |> set(key: "_measurement", value: "embedding")
    |> to(bucket: "perception_db")

  return tables
}
