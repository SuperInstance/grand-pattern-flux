# Grand Pattern — Flux Orchestration Layer

> **Fibonacci Dual-Direction Architecture** — Pure Flux implementation for InfluxDB

This repository contains the **Flux query language** orchestration and time-series layer of the [Grand Pattern](https://github.com/SuperInstance) system. It runs inside InfluxDB and handles tick ingestion, vibe computation, cross-room correlation, garbage collection triggers, balance verification, murmur routing, and surprise detection.

## What This Does

Flux is the **nervous system** of the Grand Pattern. It doesn't run computation kernels — it orchestrates the flow of perceptions, predictions, and vibes across a distributed sensor mesh organized into rooms.

| Capability | Description |
|---|---|
| **Tick Ingestion** | Store sensor readings and generate rolling predictions |
| **Vibe Computation** | Centroid position, velocity (1st derivative), acceleration (2nd derivative) |
| **Cross-Room Correlation** | Cosine similarity between room vibe trajectories |
| **Balance Checks** | Verify perception count = prediction count per room |
| **GC Triggers** | Detect when a room's embedding count exceeds threshold |
| **Murmur Routing** | Broadcast vibe summaries between neighboring rooms |
| **Surprise Detection** | Alert when prediction error exceeds threshold |
| **Anomaly Detection** | Flag spikes relative to baseline prediction error |

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           Grand Pattern System           │
                    │                                         │
  Sensors ──tick──► │  ┌──────────────┐   ┌───────────────┐  │
                    │  │perception_db │   │prediction_db  │  │
                    │  └──────┬───────┘   └───────┬───────┘  │
                    │         │                   │          │
                    │         ▼                   ▼          │
                    │     compute_vibe        balance_check  │
                    │         │                   │          │
                    │         ▼                   ▼          │
                    │  ┌──────────────┐        alerts       │
                    │  │    vibes     │                    │
                    │  └──────┬───────┘                    │
                    │    ┌────┴────┐                       │
                    │    ▼         ▼                       │
                    │ correlate   murmur ──► neighbor      │
                    │    │         rooms                   │
                    │    ▼                                │
                    │  correlations                       │
                    │                                      │
                    │  gc_trigger ──► gc_reports           │
                    │  detect_surprise ──► surprises       │
                    └─────────────────────────────────────────┘
```

## Buckets

| Bucket | Purpose |
|---|---|
| `perception_db` | Raw sensor embeddings per room |
| `prediction_db` | Rolling-average predictions per room |
| `vibes` | Computed vibe state (position, velocity, acceleration) |
| `gc_reports` | Garbage collection audit trail |
| `surprises` | Prediction error events |
| `murmurs` | Inter-room vibe summaries |
| `correlations` | Cross-room cosine similarity |

Each bucket uses measurement schemas with 8-dimensional embeddings (`d0`–`d7`) as fields, `room_id` and `sensor_id` as tags.

## Directory Layout

```
grand-pattern-flux/
├── README.md               ← you are here
├── buckets/                # Bucket schema definitions
│   ├── perception.flux
│   ├── prediction.flux
│   ├── vibes.flux
│   ├── gc_reports.flux
│   ├── surprises.flux
│   ├── murmurs.flux
│   └── correlations.flux
├── queries/                # Core query functions
│   ├── tick_processor.flux
│   ├── balance_check.flux
│   ├── compute_vibe.flux
│   ├── gc_trigger.flux
│   ├── correlate.flux
│   ├── murmur.flux
│   ├── detect_surprise.flux
│   └── anomaly_detection.flux
├── tasks/                  # Scheduled InfluxDB tasks
│   ├── balance_check_task.flux
│   ├── vibe_compute_task.flux
│   ├── gc_trigger_task.flux
│   ├── correlate_task.flux
│   └── murmur_task.flux
├── dashboards/             # Visualization queries
│   ├── room_health.flux
│   ├── vibe_trajectory.flux
│   ├── prediction_accuracy.flux
│   └── fleet_correlations.flux
└── tests/                  # Test queries
    ├── test_balance.flux
    ├── test_vibe.flux
    ├── test_correlate.flux
    └── test_gc.flux
```

## Quick Start

### 1. Create Buckets

```bash
influx bucket create -n perception_db -o your-org -r 30d
influx bucket create -n prediction_db -o your-org -r 30d
influx bucket create -n vibes -o your-org -r 7d
influx bucket create -n gc_reports -o your-org -r 90d
influx bucket create -n surprises -o your-org -r 30d
influx bucket create -n murmurs -o your-org -r 7d
influx bucket create -n correlations -o your-org -r 30d
```

### 2. Apply Tasks

```bash
influx task create --file tasks/vibe_compute_task.flux
influx task create --file tasks/balance_check_task.flux
influx task create --file tasks/gc_trigger_task.flux
influx task create --file tasks/correlate_task.flux
influx task create --file tasks/murmur_task.flux
```

### 3. Write a Perception (Tick)

```flux
import "array"

array.from(rows: [{
  room_id: "chamber-7",
  sensor_id: "fib-eye-01",
  _time: now(),
  _measurement: "embedding",
  d0: 0.12, d1: 0.45, d2: 0.78, d3: 0.33,
  d4: 0.91, d5: 0.56, d6: 0.22, d7: 0.67,
  strength: 0.88
}])
|> to(bucket: "perception_db")
```

### 4. Query Vibes

```flux
from(bucket: "vibes")
  |> range(start: -5m)
  |> filter(fn: (r) => r.room_id == "chamber-7")
  |> filter(fn: (r) => r._measurement == "vibe")
```

## How This Fits the Grand Pattern

This Flux layer is the **time-series backbone** that connects:

- **Sensor hardware** → perception embeddings (tick ingestion)
- **Per-room state** → vibe vectors (position/velocity/acceleration)
- **Rooms to each other** → correlations and murmurs
- **Health monitoring** → balance checks, GC, surprise detection

It is designed to work alongside (but not depend on) the Python computation kernels. The Flux layer handles streaming, scheduling, and alerting. The Python layer handles the heavy mathematical operations (full JEPA rounds, Fibonacci embedding synthesis, etc.).

## Configuration

All queries use parameters that can be overridden via Flux `option` blocks:

```flux
option gp = {
  surprise_threshold: 0.5,
  gc_max_embeddings: 10000,
  vibe_window: 5m,
  correlation_window: 30m,
  anomaly_spike_factor: 3.0,
}
```

## License

MIT

## See Also

- [Grand Pattern Architecture](https://github.com/SuperInstance) — parent organization
- [InfluxDB Flux Docs](https://docs.influxdata.com/flux/v0/) — language reference
