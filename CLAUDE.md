# lex-cognitive-volcano

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-cognitive-volcano`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::CognitiveVolcano`

## Purpose

Models cognitive pressure accumulation and eruption as a volcanic system. Magma units represent suppressed or building cognitive content (suppression, creativity, emotion, memory, frustration) that accumulate pressure over time. Chambers hold magma deposits and can erupt when critical-pressure magma is present. Eruption type is determined by the dominant magma type: suppression -> breakthrough, creativity -> insight, emotion/frustration -> outburst, memory -> catharsis.

## Gem Info

- **Gemspec**: `lex-cognitive-volcano.gemspec`
- **Require**: `lex-cognitive-volcano`
- **Ruby**: >= 3.4
- **License**: MIT
- **Homepage**: https://github.com/LegionIO/lex-cognitive-volcano

## File Structure

```
lib/legion/extensions/cognitive_volcano/
  version.rb
  helpers/
    constants.rb         # Magma/eruption types, pressure/intensity label tables, thresholds
    magma.rb             # Magma class — one pressurizable cognitive deposit
    chamber.rb           # Chamber class — holds magma, can erupt
    volcano_engine.rb    # VolcanoEngine — registry for chambers and magma
  runners/
    cognitive_volcano.rb  # Runner module — public API (extend self)
  client.rb
```

## Key Constants

| Constant | Value | Meaning |
|---|---|---|
| `MAX_CHAMBERS` | 100 | Hard cap on chambers (raises if exceeded) |
| `PRESSURE_RATE` | 0.08 | Default pressure increase per `pressurize!` call |
| `ERUPTION_THRESHOLD` | 0.85 | Pressure >= this = critical magma |
| `COOLDOWN_RATE` | 0.03 | Pressure released per `cool_all!` tick |

`MAGMA_TYPES`: `[:suppression, :creativity, :emotion, :memory, :frustration]`

`ERUPTION_TYPES`: `[:breakthrough, :outburst, :insight, :catharsis]`

Eruption type mapping (by dominant magma): `suppression -> :breakthrough`, `creativity -> :insight`, `emotion -> :outburst`, `frustration -> :outburst`, `memory -> :catharsis`

Pressure labels: `0.0..0.2` = `:dormant`, `0.2..0.4` = `:building`, `0.4..0.6` = `:active`, `0.6..0.8` = `:elevated`, `0.8..1.0` = `:critical`

Intensity labels: `0.0..0.2` = `:minor`, `0.2..0.4` = `:moderate`, `0.4..0.6` = `:significant`, `0.6..0.8` = `:major`, `0.8..1.0` = `:cataclysmic`

## Key Classes

### `Helpers::Magma`

One pressurizable cognitive deposit.

- `pressurize!(rate:)` — increases pressure by rate (default `PRESSURE_RATE`)
- `release!(amount:)` — reduces pressure by at most `amount`; returns released amount
- `critical?` — pressure >= `ERUPTION_THRESHOLD`
- `dormant?` — pressure < 0.2
- `pressure_label` — label from `PRESSURE_LABELS`
- Invalid `magma_type` raises `ArgumentError`

### `Helpers::Chamber`

A volcanic chamber holding magma deposits.

- `add_magma(magma)` — appends magma; raises temperature by 0.05 (capped at 1.0)
- `erupt!` — if no critical magma, returns `{ erupted: false, reason: :no_critical_magma }`; otherwise releases all critical magma, removes dormant deposits, lowers temperature by 0.2, lowers structural_integrity by 0.1, increments `eruption_count`; returns eruption event hash
- `reinforce!(amount:)` / `degrade!(amount:)` — adjust structural integrity
- `volatile?` — any critical magma OR structural_integrity < 0.3
- `stable?` — not volatile AND structural_integrity >= 0.7
- `average_pressure` — mean pressure across all magma deposits
- Eruption type determined by dominant magma type count via `ERUPTION_TYPE_MAP`

### `Helpers::VolcanoEngine`

Registry for chambers and magma.

- `create_magma(magma_type:, domain:, content:, source:, pressure:)` — stores in `@magma_registry`
- `create_chamber(name:, temperature:, structural_integrity:)` — raises if at `MAX_CHAMBERS`
- `pressurize_magma(magma_id:, rate:)` — delegates to magma
- `trigger_eruption(chamber_id:)` — delegates to chamber's `erupt!`; records in `@eruption_history` (ring buffer, 500 max)
- `cool_all!(rate:)` — releases `rate` pressure from all non-dormant magma; returns count cooled
- `most_volatile` — chamber with highest `average_pressure`
- `pressure_report` — aggregate with critical count, volatile chamber count, eruption history size

Note: magma is stored in `@magma_registry` independently; chambers maintain `@magma_deposits` separately. Adding magma to the registry does NOT automatically add it to a chamber — that requires `chamber.add_magma(magma)`.

## Runners

Module: `Legion::Extensions::CognitiveVolcano::Runners::CognitiveVolcano` (uses `extend self`)

| Runner | Key Args | Returns |
|---|---|---|
| `create_magma` | `magma_type:`, `domain:`, `content:`, `source:`, `pressure:` | `{ success:, magma: }` or `{ success: false, error: :invalid_magma_type }` |
| `create_chamber` | `name:`, `temperature:`, `structural_integrity:` | `{ success:, chamber: }` |
| `pressurize` | `magma_id:`, `rate:` | `{ success:, magma: }` or `{ success: false, error: :magma_not_found }` |
| `trigger_eruption` | `chamber_id:` | `{ success:, erupted:, eruption_type:, intensity:, ... }` |
| `list_chambers` | — | `{ success:, chambers:, count: }` |
| `pressure_status` | — | `{ success:, total_chambers:, critical_count:, average_pressure:, ... }` |

All runners accept optional `engine:` keyword for test injection.

## Integration Points

- No actors defined; `cool_all!` and `pressurize_magma` must be triggered externally
- Can model emotional pressure build-up alongside `lex-emotion` for a complementary pressure+valence model
- `trigger_eruption` is the culminating action — represents sudden expressive release
- All state is in-memory per `VolcanoEngine` instance

## Development Notes

- Magma and chambers are separate: magma must be explicitly added to a chamber via `chamber.add_magma(magma)` — the engine runners do not perform this linking automatically
- The runner's `trigger_eruption` merges `success:` after the fact: `result.merge(success: result[:erupted])`
- `erupt!` removes dormant deposits (pressure < 0.2) after releasing critical ones — slight behavior to be aware of in tests
- `VolcanoEngine#cool_all!` releases from `@magma_registry` (the flat registry), not from chamber deposits
