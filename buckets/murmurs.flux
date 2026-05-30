// Bucket: murmurs
// Inter-room vibe summaries — the "whispers" between rooms.
//
// Schema:
//   Measurement: murmur
//   Tags:        from_room, to_room
//   Fields:      vibe_summary (string — JSON-encoded vibe snapshot)
//   Timestamp:   _time
//
// Retention: 7 days recommended

bucket_schema = {
  name: "murmurs",
  measurement: "murmur",
  tagKeys: ["from_room", "to_room"],
  fieldKeys: ["vibe_summary"],
}
