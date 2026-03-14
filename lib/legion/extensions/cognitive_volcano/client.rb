# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveVolcano
      class Client
        include Runners::CognitiveVolcano

        attr_reader :engine

        def initialize(engine: nil, **)
          @engine = engine || Helpers::VolcanoEngine.new
        end

        def create_magma(magma_type:, domain:, content:, source:, pressure: 0.0, **)
          super(magma_type: magma_type, domain: domain, content: content,
                source: source, pressure: pressure, engine: @engine)
        end

        def create_chamber(name:, temperature: 0.5, structural_integrity: 1.0, **)
          super(name: name, temperature: temperature,
                structural_integrity: structural_integrity, engine: @engine)
        end

        def pressurize(magma_id:, rate: Helpers::Constants::PRESSURE_RATE, **)
          super(magma_id: magma_id, rate: rate, engine: @engine)
        end

        def trigger_eruption(chamber_id:, **)
          super(chamber_id: chamber_id, engine: @engine)
        end

        def list_chambers(**)
          super(engine: @engine)
        end

        def pressure_status(**)
          super(engine: @engine)
        end
      end
    end
  end
end
