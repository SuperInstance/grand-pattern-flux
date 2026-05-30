// Balance Check
// Verify that perception_db count == prediction_db count for each room.
// Imbalance indicates dropped predictions or orphaned perceptions.
//
// Parameters:
//   room_id  — room to check (omit for all rooms)
//   window   — time window to check (default: -1h)

balance_check = (room_id="", window=-1h) => {
  perceptions = from(bucket: "perception_db")
    |> range(start: window)
    |> filter(fn: (r) => if room_id != "" then r.room_id == room_id else true)
    |> filter(fn: (r) => r._measurement == "embedding")
    |> group(columns: ["room_id"])
    |> count()
    |> rename(columns: {_value: "perception_count"})

  predictions = from(bucket: "prediction_db")
    |> range(start: window)
    |> filter(fn: (r) => if room_id != "" then r.room_id == room_id else true)
    |> filter(fn: (r) => r._measurement == "prediction")
    |> group(columns: ["room_id"])
    |> count()
    |> rename(columns: {_value: "prediction_count"})

  // Join on room_id and compute imbalance
  join(tables: {p: perceptions, pred: predictions}, on: ["room_id"])
    |> map(fn: (r) => ({r with
      imbalance: r.perception_count - r.prediction_count,
      balanced: if r.perception_count == r.prediction_count then true else false,
    }))
}

// Alert on imbalance — returns only unbalanced rooms
balance_alert = (room_id="", window=-1h) =>
  balance_check(room_id: room_id, window: window)
    |> filter(fn: (r) => r.balanced == false)
