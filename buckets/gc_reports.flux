// Bucket: gc_reports
// Garbage collection audit trail per room.
//
// Schema:
//   Measurement: gc_report
//   Tags:        room_id
//   Fields:      merged_count (int), decayed_count (int), pruned_count (int)
//   Timestamp:   _time
//
// Retention: 90 days recommended

bucket_schema = {
  name: "gc_reports",
  measurement: "gc_report",
  tagKeys: ["room_id"],
  fieldKeys: ["merged_count", "decayed_count", "pruned_count"],
}
