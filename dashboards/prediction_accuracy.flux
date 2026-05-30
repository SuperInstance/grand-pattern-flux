// Dashboard: Prediction Accuracy
// Shows prediction error over time per room.

// Raw prediction errors
from(bucket: "surprises")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "surprise")
  |> filter(fn: (r) => r._field == "prediction_error")

// Error rate per room (errors per minute)
error_rate = from(bucket: "surprises")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "surprise")
  |> filter(fn: (r) => r._field == "prediction_error")
  |> group(columns: ["room_id"])
  |> aggregateWindow(every: 1m, fn: count, createEmpty: true)

// Mean error per room
mean_error = from(bucket: "surprises")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "surprise")
  |> filter(fn: (r) => r._field == "prediction_error")
  |> group(columns: ["room_id"])
  |> mean()

// Show rooms with highest mean error first
mean_error
  |> group()
  |> sort(columns: ["_value"], desc: true)
