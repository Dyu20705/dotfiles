# Startup Benchmarks

Run locally:

```bash
dot bench
dot bench --json
```

Each record contains a metric, sample count, median milliseconds, budget and
status. Results are environment-specific; CI artifacts establish regression
signals rather than universal performance claims. Network bootstrap is excluded.
