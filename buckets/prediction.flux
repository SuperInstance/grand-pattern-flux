// Bucket: prediction_db
// Stores rolling-average predictions per room.
//
// Schema:
//   Measurement: prediction
//   Tags:        room_id
//   Fields:      d0..d7 (float), confidence (float)
//   Timestamp:   _time
//
// Retention: 30 days recommended

bucket_schema = {
  name: "prediction_db",
  measurement: "prediction",
  tagKeys: ["room_id"],
  fieldKeys: [
    "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7",
    "confidence",
  ],
}

validate_prediction = (r) =>
  exists r.d0 and exists r.d1 and exists r.d2 and exists r.d3 and
  exists r.d4 and exists r.d5 and exists r.d6 and exists r.d7 and
  exists r.confidence and exists r.room_id
