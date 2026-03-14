# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveVolcano::Runners::CognitiveVolcano do
  let(:constants) { Legion::Extensions::CognitiveVolcano::Helpers::Constants }
  let(:engine)    { Legion::Extensions::CognitiveVolcano::Helpers::VolcanoEngine.new }

  # Use the module via the client so engine injection works cleanly
  let(:client) { Legion::Extensions::CognitiveVolcano::Client.new(engine: engine) }

  describe '#create_magma' do
    it 'returns success: true for valid input' do
      result = client.create_magma(magma_type: :suppression, domain: :work, content: 'test', source: 'env')
      expect(result[:success]).to be true
    end

    it 'includes magma hash in result' do
      result = client.create_magma(magma_type: :creativity, domain: :art, content: 'vision', source: 'dream')
      expect(result[:magma]).to include(:magma_id, :magma_type, :pressure)
    end

    it 'returns success: false for invalid magma_type' do
      result = client.create_magma(magma_type: :invalid, domain: :test, content: 'x', source: 'y')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_magma_type)
    end

    it 'includes valid_types in error response' do
      result = client.create_magma(magma_type: :bad, domain: :test, content: 'x', source: 'y')
      expect(result[:valid_types]).to eq(constants::MAGMA_TYPES)
    end

    it 'handles all valid magma types' do
      constants::MAGMA_TYPES.each do |type|
        result = client.create_magma(magma_type: type, domain: :test, content: 'c', source: 's')
        expect(result[:success]).to be true
      end
    end

    it 'accepts initial pressure' do
      result = client.create_magma(magma_type: :emotion, domain: :self, content: 'surge', source: 'body', pressure: 0.5)
      expect(result[:magma][:pressure]).to eq(0.5)
    end
  end

  describe '#create_chamber' do
    it 'returns success: true for valid input' do
      result = client.create_chamber(name: 'primary')
      expect(result[:success]).to be true
    end

    it 'includes chamber hash in result' do
      result = client.create_chamber(name: 'main')
      expect(result[:chamber]).to include(:chamber_id, :name, :temperature, :structural_integrity)
    end

    it 'accepts custom temperature' do
      result = client.create_chamber(name: 'hot', temperature: 0.9)
      expect(result[:chamber][:temperature]).to eq(0.9)
    end

    it 'accepts custom structural_integrity' do
      result = client.create_chamber(name: 'solid', structural_integrity: 0.8)
      expect(result[:chamber][:structural_integrity]).to eq(0.8)
    end
  end

  describe '#pressurize' do
    it 'pressurizes an existing magma' do
      m_result = client.create_magma(magma_type: :suppression, domain: :work, content: 'test', source: 's')
      mid = m_result[:magma][:magma_id]
      result = client.pressurize(magma_id: mid)
      expect(result[:success]).to be true
      expect(result[:magma][:pressure]).to be > 0.0
    end

    it 'returns success: false for unknown magma_id' do
      result = client.pressurize(magma_id: 'no-such-id')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:magma_not_found)
    end

    it 'accepts custom rate' do
      m_result = client.create_magma(magma_type: :creativity, domain: :art, content: 'x', source: 's')
      mid = m_result[:magma][:magma_id]
      result = client.pressurize(magma_id: mid, rate: 0.5)
      expect(result[:magma][:pressure]).to be_within(0.001).of(0.5)
    end
  end

  describe '#trigger_eruption' do
    it 'returns success: false when no critical magma' do
      c_result = client.create_chamber(name: 'quiet')
      cid = c_result[:chamber][:chamber_id]
      result = client.trigger_eruption(chamber_id: cid)
      expect(result[:success]).to be false
    end

    it 'returns success: true when eruption occurs' do
      c_result = client.create_chamber(name: 'volatile')
      cid = c_result[:chamber][:chamber_id]

      m = engine.get_chamber(cid)
      magma = engine.create_magma(magma_type: :suppression, domain: :work, content: 'pent-up', source: 's',
                                  pressure: constants::ERUPTION_THRESHOLD)
      m.add_magma(magma)

      result = client.trigger_eruption(chamber_id: cid)
      expect(result[:success]).to be true
    end

    it 'returns chamber_not_found for unknown chamber_id' do
      result = client.trigger_eruption(chamber_id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:chamber_not_found)
    end

    it 'includes eruption_type when erupted' do
      c_result = client.create_chamber(name: 'active')
      cid = c_result[:chamber][:chamber_id]
      chamber = engine.get_chamber(cid)
      magma = engine.create_magma(magma_type: :memory, domain: :past, content: 'recall', source: 'deep',
                                  pressure: constants::ERUPTION_THRESHOLD)
      chamber.add_magma(magma)

      result = client.trigger_eruption(chamber_id: cid)
      expect(constants::ERUPTION_TYPES).to include(result[:eruption_type])
    end
  end

  describe '#list_chambers' do
    it 'returns success: true' do
      expect(client.list_chambers[:success]).to be true
    end

    it 'returns empty array when no chambers created' do
      expect(client.list_chambers[:chambers]).to eq([])
    end

    it 'returns all created chambers' do
      client.create_chamber(name: 'alpha')
      client.create_chamber(name: 'beta')
      result = client.list_chambers
      expect(result[:count]).to eq(2)
      names = result[:chambers].map { |c| c[:name] }
      expect(names).to include('alpha', 'beta')
    end
  end

  describe '#pressure_status' do
    it 'returns success: true' do
      expect(client.pressure_status[:success]).to be true
    end

    it 'includes expected keys' do
      result = client.pressure_status
      expect(result).to include(:total_chambers, :total_magma, :critical_count, :average_pressure, :pressure_label)
    end

    it 'reflects current state' do
      client.create_chamber(name: 'main')
      client.create_magma(magma_type: :frustration, domain: :work, content: 'a', source: 'b')
      result = client.pressure_status
      expect(result[:total_chambers]).to eq(1)
      expect(result[:total_magma]).to eq(1)
    end
  end
end
