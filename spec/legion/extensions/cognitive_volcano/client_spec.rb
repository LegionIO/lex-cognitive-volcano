# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveVolcano::Client do
  let(:constants) { Legion::Extensions::CognitiveVolcano::Helpers::Constants }
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a VolcanoEngine by default' do
      expect(client.engine).to be_a(Legion::Extensions::CognitiveVolcano::Helpers::VolcanoEngine)
    end

    it 'accepts an injected engine' do
      engine = Legion::Extensions::CognitiveVolcano::Helpers::VolcanoEngine.new
      c = described_class.new(engine: engine)
      expect(c.engine).to eq(engine)
    end
  end

  describe 'full workflow' do
    it 'creates magma, assigns to chamber, pressurizes, and erupts' do
      # Create a chamber
      c_result = client.create_chamber(name: 'pressure_chamber')
      expect(c_result[:success]).to be true
      cid = c_result[:chamber][:chamber_id]

      # Create magma
      m_result = client.create_magma(
        magma_type: :suppression,
        domain:     :work,
        content:    'years of silence',
        source:     'meetings'
      )
      expect(m_result[:success]).to be true
      mid = m_result[:magma][:magma_id]

      # Assign magma to chamber via engine directly
      magma   = client.engine.get_magma(mid)
      chamber = client.engine.get_chamber(cid)
      chamber.add_magma(magma)

      # Pressurize until critical
      15.times { client.pressurize(magma_id: mid) }
      expect(magma.critical?).to be true

      # Trigger eruption
      eruption = client.trigger_eruption(chamber_id: cid)
      expect(eruption[:success]).to be true
      expect(eruption[:eruption_type]).to eq(:breakthrough)
    end

    it 'tracks eruption history' do
      c_result = client.create_chamber(name: 'historic')
      cid = c_result[:chamber][:chamber_id]

      3.times do
        m = client.engine.create_magma(
          magma_type: :emotion,
          domain:     :stress,
          content:    'spike',
          source:     'env',
          pressure:   constants::ERUPTION_THRESHOLD
        )
        client.engine.get_chamber(cid).add_magma(m)
        client.trigger_eruption(chamber_id: cid)
      end

      status = client.pressure_status
      expect(status[:eruption_count]).to eq(3)
    end
  end

  describe '#list_chambers delegation' do
    it 'uses the client engine' do
      client.create_chamber(name: 'test')
      result = client.list_chambers
      expect(result[:count]).to eq(1)
    end
  end

  describe '#pressure_status delegation' do
    it 'returns aggregated system state' do
      client.create_chamber(name: 'c1')
      client.create_magma(magma_type: :creativity, domain: :art, content: 'spark', source: 'muse')
      result = client.pressure_status
      expect(result[:total_chambers]).to eq(1)
      expect(result[:total_magma]).to eq(1)
    end
  end
end
