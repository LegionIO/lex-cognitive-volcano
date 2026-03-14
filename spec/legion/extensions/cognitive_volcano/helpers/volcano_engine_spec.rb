# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveVolcano::Helpers::VolcanoEngine do
  let(:constants) { Legion::Extensions::CognitiveVolcano::Helpers::Constants }
  let(:engine)    { described_class.new }

  def add_magma(type: :suppression, pressure: 0.0)
    engine.create_magma(magma_type: type, domain: :test, content: 'x', source: 'y', pressure: pressure)
  end

  def add_chamber(name: 'test')
    engine.create_chamber(name: name)
  end

  describe '#create_magma' do
    it 'creates and returns a Magma instance' do
      magma = add_magma
      expect(magma).to be_a(Legion::Extensions::CognitiveVolcano::Helpers::Magma)
    end

    it 'stores the magma in the registry' do
      magma = add_magma
      expect(engine.get_magma(magma.magma_id)).to eq(magma)
    end

    it 'accepts all magma types' do
      constants::MAGMA_TYPES.each do |type|
        m = add_magma(type: type)
        expect(m.magma_type).to eq(type)
      end
    end

    it 'sets initial pressure' do
      magma = add_magma(pressure: 0.4)
      expect(magma.pressure).to eq(0.4)
    end
  end

  describe '#create_chamber' do
    it 'creates and returns a Chamber instance' do
      chamber = add_chamber
      expect(chamber).to be_a(Legion::Extensions::CognitiveVolcano::Helpers::Chamber)
    end

    it 'stores the chamber' do
      chamber = add_chamber
      expect(engine.get_chamber(chamber.chamber_id)).to eq(chamber)
    end

    it 'raises ArgumentError at MAX_CHAMBERS limit' do
      stub_const('Legion::Extensions::CognitiveVolcano::Helpers::Constants::MAX_CHAMBERS', 2)
      add_chamber(name: 'c1')
      add_chamber(name: 'c2')
      expect { add_chamber(name: 'c3') }.to raise_error(ArgumentError, /chamber limit/)
    end
  end

  describe '#pressurize_magma' do
    it 'pressurizes an existing magma' do
      magma = add_magma
      engine.pressurize_magma(magma_id: magma.magma_id)
      expect(magma.pressure).to be > 0.0
    end

    it 'returns nil for unknown magma_id' do
      result = engine.pressurize_magma(magma_id: 'no-such-id')
      expect(result).to be_nil
    end

    it 'accepts custom rate' do
      magma = add_magma
      engine.pressurize_magma(magma_id: magma.magma_id, rate: 0.3)
      expect(magma.pressure).to be_within(0.001).of(0.3)
    end
  end

  describe '#trigger_eruption' do
    it 'returns chamber_not_found for unknown chamber_id' do
      result = engine.trigger_eruption(chamber_id: 'no-such-chamber')
      expect(result[:erupted]).to be false
      expect(result[:reason]).to eq(:chamber_not_found)
    end

    it 'records eruption in history when eruption occurs' do
      chamber = add_chamber
      magma   = add_magma(pressure: constants::ERUPTION_THRESHOLD)
      chamber.add_magma(magma)
      engine.trigger_eruption(chamber_id: chamber.chamber_id)
      expect(engine.eruption_history.size).to eq(1)
    end

    it 'does not record history when no eruption' do
      chamber = add_chamber
      engine.trigger_eruption(chamber_id: chamber.chamber_id)
      expect(engine.eruption_history).to be_empty
    end

    it 'caps eruption_history at 500' do
      chamber = add_chamber
      501.times do
        m = add_magma(pressure: constants::ERUPTION_THRESHOLD)
        chamber.add_magma(m)
        engine.trigger_eruption(chamber_id: chamber.chamber_id)
      end
      expect(engine.eruption_history.size).to eq(500)
    end
  end

  describe '#cool_all!' do
    it 'releases pressure from non-dormant magma' do
      m1 = add_magma(pressure: 0.5)
      m2 = add_magma(pressure: 0.6)
      add_magma(pressure: 0.0)
      cooled = engine.cool_all!
      expect(cooled).to eq(2)
      expect(m1.pressure).to be < 0.5
      expect(m2.pressure).to be < 0.6
    end

    it 'returns 0 when all magma is dormant' do
      add_magma(pressure: 0.0)
      expect(engine.cool_all!).to eq(0)
    end
  end

  describe '#most_volatile' do
    it 'returns nil when no chambers exist' do
      expect(engine.most_volatile).to be_nil
    end

    it 'returns the chamber with highest average pressure' do
      c1 = add_chamber(name: 'low')
      c2 = add_chamber(name: 'high')

      m1 = add_magma(pressure: 0.2)
      m2 = add_magma(pressure: 0.8)
      c1.add_magma(m1)
      c2.add_magma(m2)

      expect(engine.most_volatile).to eq(c2)
    end
  end

  describe '#pressure_report' do
    it 'returns a report hash with expected keys' do
      report = engine.pressure_report
      expect(report).to include(
        :total_chambers, :total_magma, :critical_count,
        :average_pressure, :pressure_label, :volatile_chambers,
        :eruption_count, :chambers
      )
    end

    it 'counts total_chambers correctly' do
      add_chamber(name: 'a')
      add_chamber(name: 'b')
      expect(engine.pressure_report[:total_chambers]).to eq(2)
    end

    it 'counts total_magma correctly' do
      add_magma
      add_magma
      add_magma
      expect(engine.pressure_report[:total_magma]).to eq(3)
    end

    it 'counts critical magma correctly' do
      add_magma(pressure: constants::ERUPTION_THRESHOLD)
      add_magma(pressure: 0.1)
      expect(engine.pressure_report[:critical_count]).to eq(1)
    end

    it 'returns average_pressure 0.0 when no magma' do
      expect(engine.pressure_report[:average_pressure]).to eq(0.0)
    end
  end

  describe '#all_chambers and #all_magma' do
    it 'all_chambers returns all created chambers' do
      c1 = add_chamber(name: 'x')
      c2 = add_chamber(name: 'y')
      expect(engine.all_chambers).to include(c1, c2)
    end

    it 'all_magma returns all created magma' do
      m1 = add_magma
      m2 = add_magma
      expect(engine.all_magma).to include(m1, m2)
    end
  end
end
