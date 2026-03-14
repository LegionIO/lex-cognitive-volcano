# lex-cognitive-volcano

A LegionIO cognitive architecture extension that models cognitive pressure accumulation and release as a volcanic system. Suppressed thoughts, creative impulses, and emotional energy accumulate as magma that pressurizes until a chamber erupts.

## What It Does

Tracks **magma** — cognitive content of five types:

`suppression`, `creativity`, `emotion`, `memory`, `frustration`

Magma pressurizes over time. Once pressure reaches 0.85 (critical), it becomes eligible for eruption. **Chambers** hold magma deposits; when a chamber erupts, all critical magma releases and the eruption type is determined by the dominant magma:

- Suppression -> `:breakthrough`
- Creativity -> `:insight`
- Emotion/Frustration -> `:outburst`
- Memory -> `:catharsis`

## Usage

```ruby
require 'lex-cognitive-volcano'

client = Legion::Extensions::CognitiveVolcano::Client.new

# Create a volcanic chamber
chamber = client.create_chamber(name: 'emotional_pressure_chamber', temperature: 0.4)
# => { success: true, chamber: { chamber_id: "uuid...", volatile: false, stable: true, ... } }

chamber_id = chamber[:chamber][:chamber_id]

# Create magma units
m1 = client.create_magma(magma_type: :emotion, domain: :social, content: 'unresolved conflict', source: :interaction, pressure: 0.5)
# => { success: true, magma: { magma_id: "uuid...", pressure: 0.5, label: :active, critical: false, ... } }

# Pressurize magma
client.pressurize(magma_id: m1[:magma][:magma_id])
# => { success: true, magma: { pressure: 0.58, label: :active, critical: false, ... } }

# Pressurize repeatedly until critical
8.times { client.pressurize(magma_id: m1[:magma][:magma_id]) }
client.pressurize(magma_id: m1[:magma][:magma_id])
# => { success: true, magma: { pressure: 0.86+, label: :critical, critical: true, ... } }

# Check system pressure
client.pressure_status
# => { success: true, critical_count: 1, average_pressure: 0.86, pressure_label: :critical, volatile_chambers: 0, ... }

# Trigger eruption from a chamber (requires magma added to chamber directly via Chamber#add_magma)
client.trigger_eruption(chamber_id: chamber_id)
# => { success: false, erupted: false, reason: :no_critical_magma }
# (Note: magma must be added to the chamber object to trigger eruption)

# List all chambers
client.list_chambers
# => { success: true, chambers: [...], count: 1 }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
