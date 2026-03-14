# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveVolcano::Helpers::Magma do
  let(:constants) { Legion::Extensions::CognitiveVolcano::Helpers::Constants }

  let(:magma) do
    described_class.new(
      magma_type: :suppression,
      domain:     :work,
      content:    'unspoken frustration about meetings',
      source:     'daily_experience'
    )
  end

  describe '#initialize' do
    it 'assigns a unique magma_id' do
      expect(magma.magma_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets magma_type' do
      expect(magma.magma_type).to eq(:suppression)
    end

    it 'sets domain' do
      expect(magma.domain).to eq(:work)
    end

    it 'sets content' do
      expect(magma.content).to eq('unspoken frustration about meetings')
    end

    it 'sets source' do
      expect(magma.source).to eq('daily_experience')
    end

    it 'defaults pressure to 0.0' do
      expect(magma.pressure).to eq(0.0)
    end

    it 'accepts explicit pressure' do
      m = described_class.new(magma_type: :creativity, domain: :art, content: 'idea', source: 'spark', pressure: 0.5)
      expect(m.pressure).to eq(0.5)
    end

    it 'clamps pressure above 1.0' do
      m = described_class.new(magma_type: :emotion, domain: :test, content: 'x', source: 'y', pressure: 2.5)
      expect(m.pressure).to eq(1.0)
    end

    it 'clamps pressure below 0.0' do
      m = described_class.new(magma_type: :memory, domain: :test, content: 'x', source: 'y', pressure: -0.5)
      expect(m.pressure).to eq(0.0)
    end

    it 'raises ArgumentError for unknown magma_type' do
      expect do
        described_class.new(magma_type: :unknown, domain: :test, content: 'x', source: 'y')
      end.to raise_error(ArgumentError, /unknown magma_type/)
    end

    it 'records created_at timestamp' do
      before = Time.now.utc
      m = described_class.new(magma_type: :frustration, domain: :home, content: 'noise', source: 'env')
      after = Time.now.utc
      expect(m.created_at).to be >= before
      expect(m.created_at).to be <= after
    end
  end

  describe '#pressurize!' do
    it 'increases pressure by the default rate' do
      before = magma.pressure
      magma.pressurize!
      expect(magma.pressure).to be_within(0.001).of(before + constants::PRESSURE_RATE)
    end

    it 'accepts custom rate' do
      magma.pressurize!(rate: 0.2)
      expect(magma.pressure).to be_within(0.001).of(0.2)
    end

    it 'clamps at 1.0' do
      10.times { magma.pressurize!(rate: 0.2) }
      expect(magma.pressure).to eq(1.0)
    end

    it 'returns the new pressure value' do
      result = magma.pressurize!(rate: 0.1)
      expect(result).to eq(magma.pressure)
    end
  end

  describe '#release!' do
    it 'decreases pressure by the given amount' do
      magma.pressurize!(rate: 0.5)
      magma.release!(amount: 0.2)
      expect(magma.pressure).to be_within(0.001).of(0.3)
    end

    it 'returns the amount actually released' do
      magma.pressurize!(rate: 0.3)
      released = magma.release!(amount: 0.5)
      expect(released).to be_within(0.001).of(0.3)
    end

    it 'clamps pressure to 0.0 minimum' do
      magma.release!(amount: 5.0)
      expect(magma.pressure).to eq(0.0)
    end
  end

  describe '#critical?' do
    it 'returns false when pressure is below threshold' do
      magma.pressurize!(rate: 0.5)
      expect(magma.critical?).to be false
    end

    it 'returns true when pressure reaches threshold' do
      magma.pressurize!(rate: constants::ERUPTION_THRESHOLD)
      expect(magma.critical?).to be true
    end
  end

  describe '#dormant?' do
    it 'returns true when pressure is below 0.2' do
      expect(magma.dormant?).to be true
    end

    it 'returns false when pressure is at or above 0.2' do
      magma.pressurize!(rate: 0.2)
      expect(magma.dormant?).to be false
    end
  end

  describe '#pressure_label' do
    it 'returns :dormant at zero pressure' do
      expect(magma.pressure_label).to eq(:dormant)
    end

    it 'returns :critical at high pressure' do
      magma.pressurize!(rate: 0.9)
      expect(magma.pressure_label).to eq(:critical)
    end
  end

  describe '#to_h' do
    it 'returns a hash with required keys' do
      h = magma.to_h
      expect(h).to include(:magma_id, :magma_type, :domain, :content, :source, :pressure, :label, :critical, :dormant, :created_at)
    end

    it 'pressure value is rounded to 10 decimal places' do
      magma.pressurize!(rate: 0.08)
      expect(magma.to_h[:pressure]).to eq(magma.pressure.round(10))
    end
  end
end
