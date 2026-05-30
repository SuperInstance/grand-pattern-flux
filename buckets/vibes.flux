// Bucket: vibes
// Stores computed vibe state per room.
//
// Schema:
//   Measurement: vibe
//   Tags:        room_id
//   Fields:
//     pos_d0..pos_d7   — position (centroid of embedding window)
//     vel_d0..vel_d7   — velocity (1st derivative)
//     acc_d0..acc_d7   — acceleration (2nd derivative)
//     strength         — aggregate signal strength
//   Timestamp:   _time
//
// Retention: 7 days recommended

bucket_schema = {
  name: "vibes",
  measurement: "vibe",
  tagKeys: ["room_id"],
  fieldKeys: [
    "pos_d0", "pos_d1", "pos_d2", "pos_d3", "pos_d4", "pos_d5", "pos_d6", "pos_d7",
    "vel_d0", "vel_d1", "vel_d2", "vel_d3", "vel_d4", "vel_d5", "vel_d6", "vel_d7",
    "acc_d0", "acc_d1", "acc_d2", "acc_d3", "acc_d4", "acc_d5", "acc_d6", "acc_d7",
    "strength",
  ],
}
