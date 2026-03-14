# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveVolcano
      module Helpers
        class VolcanoEngine
          attr_reader :eruption_history

          def initialize
            @chambers        = {}
            @magma_registry  = {}
            @eruption_history = []
          end

          def create_magma(magma_type:, domain:, content:, source:, pressure: 0.0)
            magma = Magma.new(
              magma_type: magma_type,
              domain:     domain,
              content:    content,
              source:     source,
              pressure:   pressure
            )
            @magma_registry[magma.magma_id] = magma
            magma
          end

          def create_chamber(name:, temperature: 0.5, structural_integrity: 1.0)
            raise ArgumentError, "chamber limit of #{Constants::MAX_CHAMBERS} reached" if @chambers.size >= Constants::MAX_CHAMBERS

            chamber = Chamber.new(
              name:                 name,
              temperature:          temperature,
              structural_integrity: structural_integrity
            )
            @chambers[chamber.chamber_id] = chamber
            chamber
          end

          def pressurize_magma(magma_id:, rate: Constants::PRESSURE_RATE)
            magma = @magma_registry.fetch(magma_id, nil)
            return nil unless magma

            magma.pressurize!(rate: rate)
            magma
          end

          def trigger_eruption(chamber_id:)
            chamber = @chambers.fetch(chamber_id, nil)
            return { erupted: false, reason: :chamber_not_found } unless chamber

            result = chamber.erupt!
            if result[:erupted]
              @eruption_history << result
              @eruption_history.shift while @eruption_history.size > 500
            end
            result
          end

          def cool_all!(rate: Constants::COOLDOWN_RATE)
            cooled = 0
            @magma_registry.each_value do |magma|
              next if magma.dormant?

              magma.release!(amount: rate)
              cooled += 1
            end
            cooled
          end

          def most_volatile
            return nil if @chambers.empty?

            @chambers.values.max_by(&:average_pressure)
          end

          def pressure_report
            chambers_data = @chambers.values.map(&:to_h)
            critical_magma = @magma_registry.values.select(&:critical?)
            total_pressure = @magma_registry.values.sum(&:pressure)
            avg_pressure   = @magma_registry.empty? ? 0.0 : total_pressure / @magma_registry.size

            {
              total_chambers:  @chambers.size,
              total_magma:     @magma_registry.size,
              critical_count:  critical_magma.size,
              average_pressure: avg_pressure.round(10),
              pressure_label:  Constants.label_for(Constants::PRESSURE_LABELS, avg_pressure),
              volatile_chambers: @chambers.values.count(&:volatile?),
              eruption_count:  @eruption_history.size,
              chambers:        chambers_data
            }
          end

          def get_chamber(chamber_id)
            @chambers[chamber_id]
          end

          def get_magma(magma_id)
            @magma_registry[magma_id]
          end

          def all_chambers
            @chambers.values
          end

          def all_magma
            @magma_registry.values
          end
        end
      end
    end
  end
end
