# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveVolcano
      module Runners
        module CognitiveVolcano
          extend self

          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def create_magma(magma_type:, domain:, content:, source:, pressure: 0.0, engine: nil, **)
            unless Helpers::Constants::MAGMA_TYPES.include?(magma_type)
              return { success: false, error: :invalid_magma_type, valid_types: Helpers::Constants::MAGMA_TYPES }
            end

            magma = resolve_engine(engine).create_magma(
              magma_type: magma_type,
              domain:     domain,
              content:    content,
              source:     source,
              pressure:   pressure
            )

            Legion::Logging.debug "[cognitive_volcano] created magma type=#{magma_type} domain=#{domain} " \
                                  "pressure=#{magma.pressure.round(2)} id=#{magma.magma_id[0..7]}"

            { success: true, magma: magma.to_h }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def create_chamber(name:, temperature: 0.5, structural_integrity: 1.0, engine: nil, **)
            chamber = resolve_engine(engine).create_chamber(
              name:                 name,
              temperature:          temperature,
              structural_integrity: structural_integrity
            )

            Legion::Logging.debug "[cognitive_volcano] created chamber name=#{name} id=#{chamber.chamber_id[0..7]}"

            { success: true, chamber: chamber.to_h }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def pressurize(magma_id:, rate: Helpers::Constants::PRESSURE_RATE, engine: nil, **)
            magma = resolve_engine(engine).pressurize_magma(magma_id: magma_id, rate: rate)
            return { success: false, error: :magma_not_found, magma_id: magma_id } unless magma

            Legion::Logging.debug "[cognitive_volcano] pressurized magma=#{magma_id[0..7]} " \
                                  "pressure=#{magma.pressure.round(2)} critical=#{magma.critical?}"

            { success: true, magma: magma.to_h }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def trigger_eruption(chamber_id:, engine: nil, **)
            result = resolve_engine(engine).trigger_eruption(chamber_id: chamber_id)

            if result[:erupted]
              Legion::Logging.info "[cognitive_volcano] eruption! chamber=#{chamber_id[0..7]} " \
                                   "type=#{result[:eruption_type]} intensity=#{result[:intensity_label]}"
            else
              Legion::Logging.debug "[cognitive_volcano] no eruption chamber=#{chamber_id[0..7]} reason=#{result[:reason]}"
            end

            result.merge(success: result[:erupted])
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def list_chambers(engine: nil, **)
            chambers = resolve_engine(engine).all_chambers.map(&:to_h)
            Legion::Logging.debug "[cognitive_volcano] list_chambers count=#{chambers.size}"
            { success: true, chambers: chambers, count: chambers.size }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def pressure_status(engine: nil, **)
            report = resolve_engine(engine).pressure_report
            Legion::Logging.debug "[cognitive_volcano] pressure_status avg=#{report[:pressure_label]} " \
                                  "critical=#{report[:critical_count]}"
            report.merge(success: true)
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          private

          def resolve_engine(engine)
            engine || volcano_engine
          end

          def volcano_engine
            @volcano_engine ||= Helpers::VolcanoEngine.new
          end
        end
      end
    end
  end
end
