# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveVolcano
      module Helpers
        class Magma
          attr_reader :magma_id, :magma_type, :domain, :content, :source, :created_at, :pressure

          def initialize(magma_type:, domain:, content:, source:, pressure: 0.0)
            unless Constants::MAGMA_TYPES.include?(magma_type)
              raise ArgumentError, "unknown magma_type: #{magma_type.inspect}; " \
                                   "must be one of #{Constants::MAGMA_TYPES.inspect}"
            end

            @magma_id   = SecureRandom.uuid
            @magma_type = magma_type
            @domain     = domain
            @content    = content
            @source     = source
            @pressure   = pressure.clamp(0.0, 1.0)
            @created_at = Time.now.utc
          end

          def pressurize!(rate: Constants::PRESSURE_RATE)
            @pressure = (@pressure + rate).clamp(0.0, 1.0)
            @pressure
          end

          def release!(amount:)
            released  = [amount, @pressure].min
            @pressure = (@pressure - released).clamp(0.0, 1.0)
            released
          end

          def critical?
            @pressure >= Constants::ERUPTION_THRESHOLD
          end

          def dormant?
            @pressure < 0.2
          end

          def pressure_label
            Constants.label_for(Constants::PRESSURE_LABELS, @pressure)
          end

          def to_h
            {
              magma_id:   @magma_id,
              magma_type: @magma_type,
              domain:     @domain,
              content:    @content,
              source:     @source,
              pressure:   @pressure.round(10),
              label:      pressure_label,
              critical:   critical?,
              dormant:    dormant?,
              created_at: @created_at
            }
          end
        end
      end
    end
  end
end
