// Bucket: perception_db
// Stores raw sensor embeddings per room.
//
// Schema:
//   Measurement: embedding
//   Tags:        room_id, sensor_id
//   Fields:      d0..d7 (float), strength (float)
//   Timestamp:   _time
//
// Retention: 30 days recommended
//
// Example write:
//   d0: 0.12, d1: 0.45, d2: 0.78, d3: 0.33,
//   d4: 0.91, d5: 0.56, d6: 0.22, d7: 0.67,
//   strength: 0.88

bucket_schema = {
  name: "perception_db",
  measurement: "embedding",
  tagKeys: ["room_id", "sensor_id"],
  fieldKeys: [
    "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7",
    "strength",
  ],
}

// Validation helper: ensure all 8 embedding dimensions are present
validate_perception = (r) =>
  exists r.d0 and exists r.d1 and exists r.d2 and exists r.d3 and
  exists r.d4 and exists r.d5 and exists r.d6 and exists r.d7 and
  exists r.strength and
  exists r.room_id and exists r.sensor_id
