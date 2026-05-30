// Detect Surprise
// Monitor the surprises bucket for prediction errors exceeding threshold.
// Returns active surprise events for alerting.
//
// Parameters:
//   room_id   — room to monitor (omit for all)
//   threshold — minimum error to flag (default: 0.5)
//   window    — lookback window (default: -5m)

detect_surprise = (room_id="", threshold=0.5, window=-5m) => {
  from(bucket: "surprises")
    |> range(start: window)
    |> filter(fn: (r) => if room_id != "" then r.room_id == room_id else true)
    |> filter(fn: (r) => r._measurement == "surprise")
    |> filter(fn: (r) => r._field == "prediction_error")
    |> filter(fn: (r) => r._value > threshold)
    |> group(columns: ["room_id"])
    |> max()
}

// Recent surprise rate — how many surprises per minute
surprise_rate = (room_id="", window=-1h) => {
  from(bucket: "surprises")
    |> range(start: window)
    |> filter(fn: (r) => if room_id != "" then r.room_id == room_id else true)
    |> filter(fn: (r) => r._measurement == "surprise")
    |> group(columns: ["room_id"])
    |> aggregateWindow(every: 1m, fn: count, createEmpty: true)
}
