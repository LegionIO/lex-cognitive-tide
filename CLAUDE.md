# lex-cognitive-tide

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Circadian-like cognitive rhythm engine for the LegionIO cognitive architecture. Models cognition as tidal forces produced by multiple sinusoidal oscillators. High tide marks peak cognitive performance; low tide marks rest and consolidation. Tidal pools accumulate ideas during low tide and release them when the tide rises.

## Gem Info

- **Gem name**: `lex-cognitive-tide`
- **Version**: `0.1.1`
- **Module**: `Legion::Extensions::CognitiveTide`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_tide/
  version.rb
  helpers/
    constants.rb    # TIDE_PHASES, OSCILLATOR_TYPES, MAX_POOLS, POOL_EVAPORATION_RATE, TIDE_LABELS
    oscillator.rb   # Single rhythm source: sinusoidal value_at(time), tick!, in_phase_with?, to_h
    tidal_pool.rb   # Idea accumulator: deposit, harvest!, evaporate!, depth, full?, empty?
    tide_engine.rb  # Composite engine: add_oscillator, composite_tide_level, current_phase,
                    #   create_pool, deposit_to_pool, harvest_pools, evaporate_all!, tide_forecast,
                    #   high_tide?, low_tide?, tide_report
  runners/
    cognitive_tide.rb  # add_oscillator, check_tide, deposit_idea, harvest, tide_forecast, tide_status,
                       # tide_maintenance
  actors/
    tide_cycle.rb      # TideCycle - Every 60s, calls tide_maintenance
  client.rb
spec/
  legion/extensions/cognitive_tide/
    helpers/
      constants_spec.rb
      oscillator_spec.rb
      tidal_pool_spec.rb
      tide_engine_spec.rb
    runners/
      cognitive_tide_spec.rb
    actors/
      tide_cycle_spec.rb
    client_spec.rb
```

## Key Constants (Helpers::Constants)

```ruby
TIDE_PHASES          = %i[rising high_tide falling low_tide]
OSCILLATOR_TYPES     = %i[primary secondary lunar]
MAX_POOLS            = 50
POOL_EVAPORATION_RATE = 0.01
TIDE_LABELS          = range-based lookup from 0.0 (ebb) to 1.0 (peak)
SPRING_TIDE_PHASE_TOLERANCE = 0.15  # fraction of combined amplitude
HARVEST_RISING_THRESHOLD    = 0.3   # minimum tide level to permit harvest
FORECAST_RESOLUTION         = 300   # seconds between forecast samples
```

## Oscillator Model

Each `Oscillator` computes a sinusoidal value normalized to `[0, amplitude]`:

```
value_at(t) = ((sin((2π * t / period) + phase_offset) + 1) / 2) * amplitude
```

- `period`: oscillation cycle in seconds (e.g., 86400 for daily, 2551443 for lunar)
- `amplitude`: contribution weight clamped to `[0, 1]`
- `phase_offset`: shift in radians; controls when the oscillator peaks

## Composite Tide Level

`TideEngine#composite_tide_level` sums all oscillator `current_value` calls and normalizes by total amplitude:

```
level = sum(oscillator.current_value) / sum(oscillator.amplitude)   # clamped [0, 1]
```

This produces **spring tides** (amplified) when oscillators are in phase, and **neap tides** (diminished) when they cancel.

## Tide Phase Classification

| Condition | Phase |
|-----------|-------|
| level >= 0.65 | `:high_tide` |
| level <= 0.35 | `:low_tide` |
| level > previous_level (5 min ago) | `:rising` |
| else | `:falling` |

## Tidal Pools

Pools accumulate ideas during low tide and are harvested only when tide is `:rising`. This creates a natural cycle: ideas deposited during cognitive rest surface when performance is increasing.

- `deposit(item)` — adds item, silently drops if full
- `harvest!` — returns all items and clears the pool
- `evaporate!(rate)` — removes `ceil(size * rate)` oldest items; default rate = `POOL_EVAPORATION_RATE`
- `depth` — `size / capacity` as a float in `[0, 1]`

`MAX_POOLS = 50` limits total pools per engine instance.

## Actors

| Actor | Interval | Runner Method | What It Does |
|-------|----------|---------------|--------------|
| `TideCycle` | Every 60s | `tide_maintenance` | Calls `evaporate_all!` on all tidal pools (removes oldest items at `POOL_EVAPORATION_RATE`), then calls `tick!` on each oscillator to advance their internal time state |

## Runner Pattern

All runners use `extend self`, `**` splat, `engine: nil` injection, and return `{ success: true/false, ... }` hashes. `rescue ArgumentError` at runner boundary prevents propagation.

The `engine:` kwarg enables dependency injection for testing — each runner method falls back to a memoized `@tide_engine` when no engine is provided.

## Integration Points

- **lex-tick**: not currently wired in lex-cortex's PHASE_MAP — must be called manually; low tide aligns conceptually with `dormant_active` dream mode
- **lex-memory**: pool domains map naturally to memory trace domains; harvested ideas can feed `reinforce` calls
- **lex-emotion**: arousal/valence can modulate oscillator amplitude (high-arousal -> boosted primary oscillator)

## Development Notes

- `TidalPool#empty?` delegates to `@items.empty?` — required by `TideEngine#harvest_pools`
- `TideEngine#previous_level` looks back `FORECAST_RESOLUTION` seconds (300s default) to determine phase direction
- `in_phase_with?` uses combined amplitude as tolerance denominator — zero-amplitude oscillators are never in phase
- Specs mock `Time.now` with `allow(Time).to receive(:now).and_return(t)` for deterministic tide level assertions
- `tide_maintenance` is the only runner method that advances oscillator state — without the `TideCycle` actor running, oscillators compute tide level from wall-clock time directly via `value_at(Time.now)` but do not advance via `tick!`
