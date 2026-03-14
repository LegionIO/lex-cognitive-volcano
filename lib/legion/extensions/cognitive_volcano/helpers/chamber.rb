# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveVolcano
      module Helpers
        class Chamber
          attr_reader :chamber_id, :name, :temperature, :structural_integrity, :magma_deposits, :eruption_count

          def initialize(name:, temperature: 0.5, structural_integrity: 1.0)
            @chamber_id          = SecureRandom.uuid
            @name                = name
            @temperature         = temperature.clamp(0.0, 1.0)
            @structural_integrity = structural_integrity.clamp(0.0, 1.0)
            @magma_deposits      = []
            @eruption_count      = 0
            @created_at          = Time.now.utc
          end

          def add_magma(magma)
            raise ArgumentError, 'magma must be a Magma instance' unless magma.is_a?(Magma)

            @magma_deposits << magma
            @temperature = [@temperature + 0.05, 1.0].min
            magma
          end

          def erupt!
            critical = @magma_deposits.select(&:critical?)
            return { erupted: false, reason: :no_critical_magma } if critical.empty?

            eruption_type   = determine_eruption_type(critical)
            total_pressure  = critical.sum(&:pressure)
            avg_pressure    = total_pressure / critical.size
            intensity       = avg_pressure.clamp(0.0, 1.0)

            critical.each { |m| m.release!(amount: m.pressure) }
            @magma_deposits.reject! { |m| m.dormant? }

            @temperature         = [@temperature - 0.2, 0.0].max
            @structural_integrity = [@structural_integrity - 0.1, 0.0].max
            @eruption_count      += 1

            {
              erupted:       true,
              chamber_id:    @chamber_id,
              eruption_type: eruption_type,
              intensity:     intensity.round(10),
              intensity_label: Constants.label_for(Constants::INTENSITY_LABELS, intensity),
              magma_count:   critical.size,
              domains:       critical.map(&:domain).uniq,
              erupted_at:    Time.now.utc
            }
          end

          def reinforce!(amount: 0.1)
            @structural_integrity = [@structural_integrity + amount, 1.0].min
            @structural_integrity
          end

          def degrade!(amount: 0.05)
            @structural_integrity = [@structural_integrity - amount, 0.0].max
            @structural_integrity
          end

          def volatile?
            @magma_deposits.any?(&:critical?) || @structural_integrity < 0.3
          end

          def stable?
            !volatile? && @structural_integrity >= 0.7
          end

          def average_pressure
            return 0.0 if @magma_deposits.empty?

            @magma_deposits.sum(&:pressure) / @magma_deposits.size
          end

          def to_h
            {
              chamber_id:           @chamber_id,
              name:                 @name,
              temperature:          @temperature.round(10),
              structural_integrity: @structural_integrity.round(10),
              magma_count:          @magma_deposits.size,
              average_pressure:     average_pressure.round(10),
              volatile:             volatile?,
              stable:               stable?,
              eruption_count:       @eruption_count,
              created_at:           @created_at
            }
          end

          private

          def determine_eruption_type(critical_deposits)
            type_counts = critical_deposits.each_with_object(Hash.new(0)) do |m, counts|
              counts[m.magma_type] += 1
            end

            dominant = type_counts.max_by { |_type, count| count }&.first

            case dominant
            when :suppression then :breakthrough
            when :creativity  then :insight
            when :emotion     then :outburst
            when :memory      then :catharsis
            when :frustration then :outburst
            else                   :breakthrough
            end
          end
        end
      end
    end
  end
end
