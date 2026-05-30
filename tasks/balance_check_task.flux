// Task: Balance Check
// Runs every 5 minutes to verify perception/prediction balance per room.

option task = {name: "balance-check", every: 5m}

// Import the balance check query logic
balance_alert = () => {
  perceptions = from(bucket: "perception_db")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "embedding")
    |> group(columns: ["room_id"])
    |> count()
    |> rename(columns: {_value: "perception_count"})

  predictions = from(bucket: "prediction_db")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "prediction")
    |> group(columns: ["room_id"])
    |> count()
    |> rename(columns: {_value: "prediction_count"})

  return join(tables: {p: perceptions, pred: predictions}, on: ["room_id"])
    |> map(fn: (r) => ({r with
      imbalance: r.perception_count - r.prediction_count,
      balanced: r.perception_count == r.prediction_count,
    }))
    |> filter(fn: (r) => r.balanced == false)
}

// Run and output (alert system consumes this)
balance_alert()
