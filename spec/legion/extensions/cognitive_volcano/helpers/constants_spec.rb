# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveVolcano::Helpers::Constants do
  describe 'MAGMA_TYPES' do
    it 'contains the five expected types' do
      expect(described_class::MAGMA_TYPES).to contain_exactly(
        :suppression, :creativity, :emotion, :memory, :frustration
      )
    end

    it 'is frozen' do
      expect(described_class::MAGMA_TYPES).to be_frozen
    end
  end

  describe 'ERUPTION_TYPES' do
    it 'contains the four expected types' do
      expect(described_class::ERUPTION_TYPES).to contain_exactly(
        :breakthrough, :outburst, :insight, :catharsis
      )
    end

    it 'is frozen' do
      expect(described_class::ERUPTION_TYPES).to be_frozen
    end
  end

  describe 'numeric constants' do
    it 'MAX_CHAMBERS is 100' do
      expect(described_class::MAX_CHAMBERS).to eq(100)
    end

    it 'PRESSURE_RATE is 0.08' do
      expect(described_class::PRESSURE_RATE).to eq(0.08)
    end

    it 'ERUPTION_THRESHOLD is 0.85' do
      expect(described_class::ERUPTION_THRESHOLD).to eq(0.85)
    end

    it 'COOLDOWN_RATE is 0.03' do
      expect(described_class::COOLDOWN_RATE).to eq(0.03)
    end
  end

  describe '.label_for' do
    it 'returns :dormant for low pressure' do
      expect(described_class.label_for(described_class::PRESSURE_LABELS, 0.05)).to eq(:dormant)
    end

    it 'returns :building for moderate-low pressure' do
      expect(described_class.label_for(described_class::PRESSURE_LABELS, 0.3)).to eq(:building)
    end

    it 'returns :active for mid pressure' do
      expect(described_class.label_for(described_class::PRESSURE_LABELS, 0.5)).to eq(:active)
    end

    it 'returns :elevated for high pressure' do
      expect(described_class.label_for(described_class::PRESSURE_LABELS, 0.7)).to eq(:elevated)
    end

    it 'returns :critical for near-max pressure' do
      expect(described_class.label_for(described_class::PRESSURE_LABELS, 0.9)).to eq(:critical)
    end

    it 'returns :minor for low intensity' do
      expect(described_class.label_for(described_class::INTENSITY_LABELS, 0.1)).to eq(:minor)
    end

    it 'returns :cataclysmic for extreme intensity' do
      expect(described_class.label_for(described_class::INTENSITY_LABELS, 0.95)).to eq(:cataclysmic)
    end

    it 'clamps values above 1.0' do
      expect(described_class.label_for(described_class::PRESSURE_LABELS, 1.5)).to eq(:critical)
    end

    it 'clamps values below 0.0' do
      expect(described_class.label_for(described_class::PRESSURE_LABELS, -0.5)).to eq(:dormant)
    end
  end
end
