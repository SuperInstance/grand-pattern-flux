// Bucket: correlations
// Cross-room cosine similarity over sliding windows.
//
// Schema:
//   Measurement: correlation
//   Tags:        room_a, room_b
//   Fields:      cosine_sim (float)
//   Timestamp:   _time
//
// Retention: 30 days recommended

bucket_schema = {
  name: "correlations",
  measurement: "correlation",
  tagKeys: ["room_a", "room_b"],
  fieldKeys: ["cosine_sim"],
}
