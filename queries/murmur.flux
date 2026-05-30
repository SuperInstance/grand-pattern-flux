// Murmur
// Aggregate a room's vibe state and route a summary to a neighbor room.
// This is how rooms "whisper" to each other about their current state.
//
// Parameters:
//   from_room — source room
//   to_room   — destination room

import "array"
import "json"

murmur = (from_room, to_room) => {
  // Get the latest vibe for the source room
  latest_vibe = from(bucket: "vibes")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "vibe")
    |> filter(fn: (r) => r.room_id == from_room)
    |> last()

  // Aggregate into a summary — position centroid
  pos_summary = latest_vibe
    |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)
    |> group()
    |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")

  // Write murmur with encoded vibe summary
  // (In production, the vibe_summary field would be a JSON string of the position vector)
  pos_summary
    |> map(fn: (r) => ({
      _time: now(),
      _measurement: "murmur",
      from_room: from_room,
      to_room: to_room,
      vibe_summary: "pos_d0=${r.pos_d0},pos_d1=${r.pos_d1},pos_d2=${r.pos_d2},pos_d3=${r.pos_d3},pos_d4=${r.pos_d4},pos_d5=${r.pos_d5},pos_d6=${r.pos_d6},pos_d7=${r.pos_d7}",
    }))
    |> array.from()
    |> to(bucket: "murmurs")

  return pos_summary
}

// Broadcast murmur to all known neighbors
murmur_broadcast = (from_room, neighbors=[]) => {
  latest = from(bucket: "vibes")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "vibe")
    |> filter(fn: (r) => r.room_id == from_room)
    |> filter(fn: (r) => r._field =~ /^pos_d[0-7]$/)
    |> last()

  // For each neighbor, write a murmur row
  // (Flux doesn't loop over arrays easily, so this is typically
  // done via separate task invocations per neighbor pair)
  return latest
}
