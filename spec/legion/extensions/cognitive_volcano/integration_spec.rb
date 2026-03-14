# frozen_string_literal: true

RSpec.describe 'CognitiveVolcano integration' do
  let(:constants)  { Legion::Extensions::CognitiveVolcano::Helpers::Constants }
  let(:magma_cls)  { Legion::Extensions::CognitiveVolcano::Helpers::Magma }
  let(:chamber_cls) { Legion::Extensions::CognitiveVolcano::Helpers::Chamber }
  let(:engine)     { Legion::Extensions::CognitiveVolcano::Helpers::VolcanoEngine.new }
  let(:client)     { Legion::Extensions::CognitiveVolcano::Client.new(engine: engine) }

  describe 'multi-type eruption cascade' do
    it 'handles multiple chambers with different dominant magma types' do
      types_and_expected = {
        suppression: :breakthrough,
        creativity:  :insight,
        emotion:     :outburst,
        memory:      :catharsis,
        frustration: :outburst
      }

      results = types_and_expected.map do |type, expected_eruption|
        chamber = chamber_cls.new(name: type.to_s)
        magma   = magma_cls.new(
          magma_type: type,
          domain:     type,
          content:    "test #{type}",
          source:     'integration',
          pressure:   constants::ERUPTION_THRESHOLD
        )
        chamber.add_magma(magma)
        eruption = chamber.erupt!
        { type: type, eruption_type: eruption[:eruption_type], expected: expected_eruption }
      end

      results.each do |r|
        expect(r[:eruption_type]).to eq(r[:expected]), "expected #{r[:type]} to produce #{r[:expected]}"
      end
    end
  end

  describe 'pressure accumulation lifecycle' do
    it 'goes dormant -> building -> critical -> erupts -> cools' do
      m = magma_cls.new(magma_type: :suppression, domain: :test, content: 'lifecycle', source: 'test')
      expect(m.pressure_label).to eq(:dormant)
      expect(m.dormant?).to be true

      # Build pressure
      6.times { m.pressurize!(rate: constants::PRESSURE_RATE) }
      expect(%i[building active elevated]).to include(m.pressure_label)

      # Continue to critical
      20.times { m.pressurize!(rate: constants::PRESSURE_RATE) }
      expect(m.critical?).to be true
      expect(m.pressure_label).to eq(:critical)

      # Release in eruption
      released = m.release!(amount: m.pressure)
      expect(released).to be > 0.0
      expect(m.dormant?).to be true
    end
  end

  describe 'cooldown mechanics' do
    it 'cool_all! reduces pressure across all non-dormant magma' do
      3.times { engine.create_magma(magma_type: :frustration, domain: :work, content: 'x', source: 'y', pressure: 0.5) }
      engine.create_magma(magma_type: :suppression, domain: :work, content: 'z', source: 'a', pressure: 0.0)

      cooled = engine.cool_all!
      expect(cooled).to eq(3)

      engine.all_magma.select { |m| m.pressure > 0 }.each do |m|
        expect(m.pressure).to be < 0.5
      end
    end
  end

  describe 'chamber integrity degradation' do
    it 'structural integrity declines with repeated eruptions' do
      chamber = chamber_cls.new(name: 'stressed')
      initial = chamber.structural_integrity

      3.times do
        magma = magma_cls.new(
          magma_type: :emotion,
          domain:     :test,
          content:    'wave',
          source:     'stress',
          pressure:   constants::ERUPTION_THRESHOLD
        )
        chamber.add_magma(magma)
        chamber.erupt!
      end

      expect(chamber.structural_integrity).to be < initial
      expect(chamber.eruption_count).to eq(3)
    end

    it 'reinforce! restores integrity after eruptions' do
      chamber = chamber_cls.new(name: 'recovering')
      magma = magma_cls.new(
        magma_type: :suppression, domain: :test, content: 'burst', source: 's',
        pressure: constants::ERUPTION_THRESHOLD
      )
      chamber.add_magma(magma)
      chamber.erupt!

      post_eruption = chamber.structural_integrity
      chamber.reinforce!(amount: 0.5)
      expect(chamber.structural_integrity).to be > post_eruption
    end
  end

  describe 'most_volatile selection' do
    it 'identifies the chamber with highest average pressure' do
      low_chamber  = engine.create_chamber(name: 'low')
      high_chamber = engine.create_chamber(name: 'high')

      low_m  = engine.create_magma(magma_type: :emotion, domain: :t, content: 'x', source: 's', pressure: 0.2)
      high_m = engine.create_magma(magma_type: :frustration, domain: :t, content: 'y', source: 's', pressure: 0.9)

      low_chamber.add_magma(low_m)
      high_chamber.add_magma(high_m)

      expect(engine.most_volatile).to eq(high_chamber)
    end
  end

  describe 'runner via module extend' do
    it 'create_magma and list_chambers work from the runner module directly' do
      runner = Object.new
      runner.extend(Legion::Extensions::CognitiveVolcano::Runners::CognitiveVolcano)

      result = runner.create_magma(magma_type: :creativity, domain: :code, content: 'an idea', source: 'lex')
      expect(result[:success]).to be true

      list = runner.list_chambers
      expect(list[:success]).to be true
    end
  end

  describe 'pressure_report labels' do
    it 'uses pressure labels that match constants table' do
      engine.create_magma(magma_type: :suppression, domain: :d, content: 'c', source: 's', pressure: 0.9)
      report = engine.pressure_report
      valid_labels = constants::PRESSURE_LABELS.map { |_range, label| label }
      expect(valid_labels).to include(report[:pressure_label])
    end
  end
end
