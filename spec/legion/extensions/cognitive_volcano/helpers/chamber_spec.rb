# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveVolcano::Helpers::Chamber do
  let(:constants) { Legion::Extensions::CognitiveVolcano::Helpers::Constants }
  let(:magma_class) { Legion::Extensions::CognitiveVolcano::Helpers::Magma }

  let(:chamber) { described_class.new(name: 'test_chamber') }

  def build_magma(type: :suppression, pressure: 0.0)
    magma_class.new(magma_type: type, domain: :test, content: 'x', source: 'y', pressure: pressure)
  end

  def critical_magma(type: :suppression)
    m = build_magma(type: type)
    m.pressurize!(rate: constants::ERUPTION_THRESHOLD)
    m
  end

  describe '#initialize' do
    it 'assigns a unique chamber_id' do
      expect(chamber.chamber_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets name' do
      expect(chamber.name).to eq('test_chamber')
    end

    it 'defaults temperature to 0.5' do
      expect(chamber.temperature).to eq(0.5)
    end

    it 'defaults structural_integrity to 1.0' do
      expect(chamber.structural_integrity).to eq(1.0)
    end

    it 'starts with empty magma_deposits' do
      expect(chamber.magma_deposits).to be_empty
    end

    it 'starts with zero eruption_count' do
      expect(chamber.eruption_count).to eq(0)
    end

    it 'clamps temperature to 0..1' do
      c = described_class.new(name: 'hot', temperature: 5.0)
      expect(c.temperature).to eq(1.0)
    end

    it 'clamps structural_integrity to 0..1' do
      c = described_class.new(name: 'broken', structural_integrity: -1.0)
      expect(c.structural_integrity).to eq(0.0)
    end
  end

  describe '#add_magma' do
    it 'adds a magma deposit' do
      magma = build_magma
      chamber.add_magma(magma)
      expect(chamber.magma_deposits).to include(magma)
    end

    it 'increases temperature slightly' do
      before = chamber.temperature
      chamber.add_magma(build_magma)
      expect(chamber.temperature).to be > before
    end

    it 'raises ArgumentError when given a non-Magma object' do
      expect { chamber.add_magma('not a magma') }.to raise_error(ArgumentError, /must be a Magma instance/)
    end

    it 'returns the magma' do
      magma = build_magma
      result = chamber.add_magma(magma)
      expect(result).to eq(magma)
    end
  end

  describe '#erupt!' do
    context 'when no critical magma' do
      it 'returns erupted: false' do
        chamber.add_magma(build_magma(pressure: 0.1))
        result = chamber.erupt!
        expect(result[:erupted]).to be false
        expect(result[:reason]).to eq(:no_critical_magma)
      end
    end

    context 'when critical magma present' do
      before { chamber.add_magma(critical_magma) }

      it 'returns erupted: true' do
        expect(chamber.erupt![:erupted]).to be true
      end

      it 'includes eruption_type' do
        result = chamber.erupt!
        expect(constants::ERUPTION_TYPES).to include(result[:eruption_type])
      end

      it 'includes intensity' do
        result = chamber.erupt!
        expect(result[:intensity]).to be_a(Numeric)
        expect(result[:intensity]).to be_between(0.0, 1.0)
      end

      it 'includes intensity_label' do
        result = chamber.erupt!
        expect(result[:intensity_label]).not_to be_nil
      end

      it 'includes erupted_at timestamp' do
        expect(chamber.erupt![:erupted_at]).to be_a(Time)
      end

      it 'increments eruption_count' do
        expect { chamber.erupt! }.to change(chamber, :eruption_count).by(1)
      end

      it 'releases pressure from critical magma' do
        magma = critical_magma
        chamber.add_magma(magma)
        chamber.erupt!
        expect(magma.dormant?).to be true
      end

      it 'decreases temperature after eruption' do
        before = chamber.temperature
        chamber.erupt!
        expect(chamber.temperature).to be <= before
      end

      it 'decreases structural_integrity after eruption' do
        before = chamber.structural_integrity
        chamber.erupt!
        expect(chamber.structural_integrity).to be < before
      end
    end

    context 'eruption type determination' do
      it 'maps suppression to breakthrough' do
        chamber.add_magma(critical_magma(type: :suppression))
        result = chamber.erupt!
        expect(result[:eruption_type]).to eq(:breakthrough)
      end

      it 'maps creativity to insight' do
        chamber.add_magma(critical_magma(type: :creativity))
        result = chamber.erupt!
        expect(result[:eruption_type]).to eq(:insight)
      end

      it 'maps emotion to outburst' do
        chamber.add_magma(critical_magma(type: :emotion))
        result = chamber.erupt!
        expect(result[:eruption_type]).to eq(:outburst)
      end

      it 'maps memory to catharsis' do
        chamber.add_magma(critical_magma(type: :memory))
        result = chamber.erupt!
        expect(result[:eruption_type]).to eq(:catharsis)
      end

      it 'maps frustration to outburst' do
        chamber.add_magma(critical_magma(type: :frustration))
        result = chamber.erupt!
        expect(result[:eruption_type]).to eq(:outburst)
      end
    end
  end

  describe '#reinforce!' do
    it 'increases structural_integrity' do
      c = described_class.new(name: 'weak', structural_integrity: 0.5)
      c.reinforce!(amount: 0.2)
      expect(c.structural_integrity).to be_within(0.001).of(0.7)
    end

    it 'clamps at 1.0' do
      chamber.reinforce!(amount: 5.0)
      expect(chamber.structural_integrity).to eq(1.0)
    end

    it 'returns new integrity value' do
      result = chamber.reinforce!(amount: 0.1)
      expect(result).to eq(chamber.structural_integrity)
    end
  end

  describe '#degrade!' do
    it 'decreases structural_integrity' do
      before = chamber.structural_integrity
      chamber.degrade!(amount: 0.1)
      expect(chamber.structural_integrity).to be_within(0.001).of(before - 0.1)
    end

    it 'clamps at 0.0' do
      chamber.degrade!(amount: 5.0)
      expect(chamber.structural_integrity).to eq(0.0)
    end
  end

  describe '#volatile?' do
    it 'returns false when no critical magma and integrity is healthy' do
      chamber.add_magma(build_magma(pressure: 0.1))
      expect(chamber.volatile?).to be false
    end

    it 'returns true when critical magma is present' do
      chamber.add_magma(critical_magma)
      expect(chamber.volatile?).to be true
    end

    it 'returns true when structural_integrity is below 0.3' do
      c = described_class.new(name: 'unstable', structural_integrity: 0.2)
      expect(c.volatile?).to be true
    end
  end

  describe '#stable?' do
    it 'returns true when no critical magma and integrity >= 0.7' do
      expect(chamber.stable?).to be true
    end

    it 'returns false when volatile' do
      chamber.add_magma(critical_magma)
      expect(chamber.stable?).to be false
    end

    it 'returns false when integrity is below 0.7' do
      c = described_class.new(name: 'degraded', structural_integrity: 0.6)
      expect(c.stable?).to be false
    end
  end

  describe '#average_pressure' do
    it 'returns 0.0 for empty chamber' do
      expect(chamber.average_pressure).to eq(0.0)
    end

    it 'computes mean pressure across deposits' do
      m1 = build_magma(pressure: 0.4)
      m2 = build_magma(pressure: 0.6)
      chamber.add_magma(m1)
      chamber.add_magma(m2)
      expect(chamber.average_pressure).to be_within(0.001).of(0.5)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = chamber.to_h
      expect(h).to include(
        :chamber_id, :name, :temperature, :structural_integrity,
        :magma_count, :average_pressure, :volatile, :stable, :eruption_count, :created_at
      )
    end

    it 'reports magma_count accurately' do
      chamber.add_magma(build_magma)
      chamber.add_magma(build_magma)
      expect(chamber.to_h[:magma_count]).to eq(2)
    end
  end
end
