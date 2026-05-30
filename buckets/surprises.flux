// Bucket: surprises
// Prediction error events — when actual perception deviates from prediction.
//
// Schema:
//   Measurement: surprise
//   Tags:        room_id
//   Fields:      prediction_error (float), threshold (float)
//   Timestamp:   _time
//
// Retention: 30 days recommended

bucket_schema = {
  name: "surprises",
  measurement: "surprise",
  tagKeys: ["room_id"],
  fieldKeys: ["prediction_error", "threshold"],
}
