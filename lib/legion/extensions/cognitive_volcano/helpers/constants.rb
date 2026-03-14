# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveVolcano
      module Helpers
        module Constants
          MAGMA_TYPES     = %i[suppression creativity emotion memory frustration].freeze
          ERUPTION_TYPES  = %i[breakthrough outburst insight catharsis].freeze

          MAX_CHAMBERS       = 100
          PRESSURE_RATE      = 0.08
          ERUPTION_THRESHOLD = 0.85
          COOLDOWN_RATE      = 0.03

          PRESSURE_LABELS = [
            [0.0..0.2,  :dormant],
            [0.2..0.4,  :building],
            [0.4..0.6,  :active],
            [0.6..0.8,  :elevated],
            [0.8..1.0,  :critical]
          ].freeze

          INTENSITY_LABELS = [
            [0.0..0.2,  :minor],
            [0.2..0.4,  :moderate],
            [0.4..0.6,  :significant],
            [0.6..0.8,  :major],
            [0.8..1.0,  :cataclysmic]
          ].freeze

          def self.label_for(table, value)
            clamped = value.clamp(0.0, 1.0)
            entry = table.find { |range, _label| range.cover?(clamped) }
            entry ? entry[1] : table.last[1]
          end
        end
      end
    end
  end
end
