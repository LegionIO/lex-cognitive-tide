# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveTide::Helpers::Constants do
  describe 'TIDE_PHASES' do
    it 'contains the four expected phases' do
      expect(described_class::TIDE_PHASES).to eq(%i[rising high_tide falling low_tide])
    end

    it 'is frozen' do
      expect(described_class::TIDE_PHASES).to be_frozen
    end
  end

  describe 'OSCILLATOR_TYPES' do
    it 'contains primary, secondary, and lunar' do
      expect(described_class::OSCILLATOR_TYPES).to eq(%i[primary secondary lunar])
    end

    it 'is frozen' do
      expect(described_class::OSCILLATOR_TYPES).to be_frozen
    end
  end

  describe 'MAX_POOLS' do
    it 'is a positive integer' do
      expect(described_class::MAX_POOLS).to be_a(Integer)
      expect(described_class::MAX_POOLS).to be > 0
    end

    it 'equals 50' do
      expect(described_class::MAX_POOLS).to eq(50)
    end
  end

  describe 'POOL_EVAPORATION_RATE' do
    it 'is a float between 0 and 1' do
      expect(described_class::POOL_EVAPORATION_RATE).to be_a(Float)
      expect(described_class::POOL_EVAPORATION_RATE).to be >= 0.0
      expect(described_class::POOL_EVAPORATION_RATE).to be <= 1.0
    end

    it 'equals 0.01' do
      expect(described_class::POOL_EVAPORATION_RATE).to eq(0.01)
    end
  end

  describe 'TIDE_LABELS' do
    it 'is frozen' do
      expect(described_class::TIDE_LABELS).to be_frozen
    end

    it 'contains five label entries' do
      expect(described_class::TIDE_LABELS.size).to eq(5)
    end

    it 'each entry has a range and a label' do
      described_class::TIDE_LABELS.each do |entry|
        expect(entry[:range]).to be_a(Range)
        expect(entry[:label]).to be_a(String)
      end
    end

    it 'covers the full [0, 1] range collectively' do
      levels = [0.0, 0.1, 0.25, 0.45, 0.65, 0.85, 1.0]
      levels.each do |level|
        matched = described_class::TIDE_LABELS.any? { |tl| tl[:range].cover?(level) }
        expect(matched).to be(true), "No label for level #{level}"
      end
    end

    it 'maps 1.0 to peak' do
      entry = described_class::TIDE_LABELS.find { |tl| tl[:range].cover?(1.0) }
      expect(entry[:label]).to eq('peak')
    end

    it 'maps 0.0 to ebb' do
      entry = described_class::TIDE_LABELS.find { |tl| tl[:range].cover?(0.0) }
      expect(entry[:label]).to eq('ebb')
    end

    it 'maps 0.75 to high' do
      entry = described_class::TIDE_LABELS.find { |tl| tl[:range].cover?(0.75) }
      expect(entry[:label]).to eq('high')
    end
  end

  describe 'HARVEST_RISING_THRESHOLD' do
    it 'is a float between 0 and 1' do
      expect(described_class::HARVEST_RISING_THRESHOLD).to be_a(Float)
      expect(described_class::HARVEST_RISING_THRESHOLD).to be_between(0.0, 1.0)
    end
  end

  describe 'FORECAST_RESOLUTION' do
    it 'is a positive integer (seconds)' do
      expect(described_class::FORECAST_RESOLUTION).to be_a(Integer)
      expect(described_class::FORECAST_RESOLUTION).to be > 0
    end
  end
end
