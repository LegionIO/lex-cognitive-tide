# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveTide::Helpers::Oscillator do
  let(:primary) { described_class.new(oscillator_type: :primary, period: 86_400, amplitude: 1.0, phase_offset: 0.0) }
  let(:secondary) { described_class.new(oscillator_type: :secondary, period: 43_200, amplitude: 0.5, phase_offset: 1.5) }

  describe '#initialize' do
    it 'assigns oscillator_type' do
      expect(primary.oscillator_type).to eq(:primary)
    end

    it 'assigns period as float' do
      expect(primary.period).to eq(86_400.0)
    end

    it 'assigns amplitude clamped to [0, 1]' do
      osc = described_class.new(oscillator_type: :lunar, period: 2_551_443, amplitude: 1.5)
      expect(osc.amplitude).to eq(1.0)
    end

    it 'clamps amplitude at 0' do
      osc = described_class.new(oscillator_type: :primary, period: 3600, amplitude: -0.5)
      expect(osc.amplitude).to eq(0.0)
    end

    it 'assigns phase_offset as float' do
      expect(secondary.phase_offset).to eq(1.5)
    end

    it 'generates a unique uuid id' do
      o1 = described_class.new(oscillator_type: :primary, period: 3600)
      o2 = described_class.new(oscillator_type: :primary, period: 3600)
      expect(o1.id).not_to eq(o2.id)
      expect(o1.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'raises ArgumentError for unknown oscillator_type' do
      expect { described_class.new(oscillator_type: :unknown, period: 3600) }
        .to raise_error(ArgumentError, /unknown oscillator_type/)
    end

    it 'raises ArgumentError when period is not positive' do
      expect { described_class.new(oscillator_type: :primary, period: 0) }
        .to raise_error(ArgumentError, /period must be positive/)
    end

    it 'raises ArgumentError for negative period' do
      expect { described_class.new(oscillator_type: :primary, period: -100) }
        .to raise_error(ArgumentError, /period must be positive/)
    end
  end

  describe '#value_at' do
    it 'returns a value between 0 and amplitude' do
      val = primary.value_at(Time.now.utc)
      expect(val).to be >= 0.0
      expect(val).to be <= primary.amplitude
    end

    it 'returns 0.0 when amplitude is 0' do
      osc = described_class.new(oscillator_type: :primary, period: 3600, amplitude: 0.0)
      expect(osc.value_at(Time.now.utc)).to eq(0.0)
    end

    it 'varies over time within a period' do
      t = Time.now.utc
      values = (0...10).map { |i| primary.value_at(t + (i * 8640)) }
      expect(values.uniq.size).to be > 1
    end

    it 'is deterministic for the same time' do
      t = Time.now.utc
      expect(primary.value_at(t)).to eq(primary.value_at(t))
    end

    it 'returns rounded value (10 decimal places)' do
      val = primary.value_at(Time.now.utc)
      expect(val).to eq(val.round(10))
    end

    it 'respects phase_offset — same period different offset yields different values' do
      # Use t = period/4 so that sin(PI/2 + 0) = 1.0 and sin(PI/2 + PI/2) = 0.0
      period = 3600
      t = Time.at(period / 4.0).utc
      o1 = described_class.new(oscillator_type: :primary, period: period, amplitude: 1.0, phase_offset: 0.0)
      o2 = described_class.new(oscillator_type: :primary, period: period, amplitude: 1.0, phase_offset: Math::PI / 2.0)
      expect(o1.value_at(t)).not_to be_within(0.05).of(o2.value_at(t))
    end
  end

  describe '#current_value' do
    it 'returns a numeric in [0, amplitude]' do
      val = primary.current_value
      expect(val).to be_a(Float)
      expect(val).to be >= 0.0
      expect(val).to be <= 1.0
    end
  end

  describe '#tick!' do
    it 'returns a numeric value' do
      expect(primary.tick!).to be_a(Float)
    end

    it 'updates last_ticked_at' do
      before = Time.now.utc
      primary.tick!
      expect(primary.to_h[:last_ticked_at]).to be >= before
    end
  end

  describe '#in_phase_with?' do
    it 'returns true when two identical oscillators are compared' do
      o1 = described_class.new(oscillator_type: :primary, period: 86_400, amplitude: 1.0, phase_offset: 0.0)
      o2 = described_class.new(oscillator_type: :primary, period: 86_400, amplitude: 1.0, phase_offset: 0.0)
      expect(o1.in_phase_with?(o2)).to be(true)
    end

    it 'returns false when oscillators are 180 degrees out of phase' do
      # At t = period/4: sin(PI/2 + 0) = 1.0 -> value = 1.0; sin(PI/2 + PI) = -1.0 -> value = 0.0
      # Difference = 1.0, tolerance = 0.15 * (1+1) = 0.30 — NOT in phase
      period = 3600
      t = Time.at(period / 4.0).utc
      allow(Time).to receive(:now).and_return(t)
      o1 = described_class.new(oscillator_type: :primary, period: period, amplitude: 1.0, phase_offset: 0.0)
      o2 = described_class.new(oscillator_type: :secondary, period: period, amplitude: 1.0, phase_offset: Math::PI)
      expect(o1.in_phase_with?(o2)).to be(false)
    end

    it 'returns false when combined amplitude is zero' do
      o1 = described_class.new(oscillator_type: :primary, period: 3600, amplitude: 0.0)
      o2 = described_class.new(oscillator_type: :secondary, period: 3600, amplitude: 0.0)
      expect(o1.in_phase_with?(o2)).to be(false)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = primary.to_h
      expect(h.keys).to include(:id, :oscillator_type, :period, :amplitude, :phase_offset,
                                :current_value, :last_ticked_at)
    end

    it 'reflects the correct oscillator_type' do
      expect(primary.to_h[:oscillator_type]).to eq(:primary)
    end

    it 'last_ticked_at is nil before first tick' do
      osc = described_class.new(oscillator_type: :primary, period: 3600)
      expect(osc.to_h[:last_ticked_at]).to be_nil
    end
  end
end
