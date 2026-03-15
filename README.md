# lex-cognitive-tide

Circadian-like cognitive rhythm engine for LegionIO. Models cognition as tidal forces: multiple oscillators create composite tide levels, tidal pools accumulate ideas during low tide, and high tide marks peak cognitive performance.

## Installation

Add to your Gemfile:

```ruby
gem 'lex-cognitive-tide'
```

## Usage

```ruby
client = Legion::Extensions::CognitiveTide::Client.new

# Add oscillators
client.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0, phase_offset: 0.0)
client.add_oscillator(oscillator_type: :secondary, period: 43_200, amplitude: 0.5, phase_offset: 1.5)

# Check current tide
status = client.tide_status
# => { level: 0.72, phase: :high_tide, label: "peak", oscillator_count: 2, pool_count: 0 }

# Deposit an idea during low tide
client.deposit_idea(domain: 'architecture', idea: 'refactor the auth layer', tide_threshold: 0.5)

# Harvest ideas when tide rises
client.harvest(min_depth: 0.1)
```

## Actors

| Actor | Interval | What It Does |
|-------|----------|--------------|
| `TideCycle` | Every 60s | Advances oscillators via `tick!` and evaporates all tidal pools at `POOL_EVAPORATION_RATE` |

## License

MIT
