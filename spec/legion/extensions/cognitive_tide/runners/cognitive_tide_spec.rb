# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveTide::Runners::CognitiveTide do
  let(:engine) { Legion::Extensions::CognitiveTide::Helpers::TideEngine.new }

  # Use extend self — call module methods directly
  subject(:runner) { described_class }

  describe '.add_oscillator' do
    it 'returns success: true with oscillator hash' do
      result = runner.add_oscillator(oscillator_type: :primary, period: 86_400, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:oscillator]).to be_a(Hash)
    end

    it 'adds the oscillator to the engine' do
      runner.add_oscillator(oscillator_type: :primary, period: 3600, engine: engine)
      expect(engine.oscillators.size).to eq(1)
    end

    it 'accepts all oscillator_types' do
      %i[primary secondary lunar].each do |type|
        result = runner.add_oscillator(oscillator_type: type, period: 3600, engine: engine)
        expect(result[:success]).to be(true)
      end
    end

    it 'returns success: false for unknown oscillator_type' do
      result = runner.add_oscillator(oscillator_type: :invalid, period: 3600, engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to be_a(String)
    end

    it 'returns success: false for non-positive period' do
      result = runner.add_oscillator(oscillator_type: :primary, period: 0, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'accepts amplitude and phase_offset kwargs' do
      result = runner.add_oscillator(oscillator_type: :secondary, period: 43_200,
                                     amplitude: 0.5, phase_offset: 1.5, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:oscillator][:amplitude]).to eq(0.5)
    end

    it 'accepts extra kwargs via ** splat without error' do
      result = runner.add_oscillator(oscillator_type: :primary, period: 3600,
                                     extra_key: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '.check_tide' do
    before { runner.add_oscillator(oscillator_type: :primary, period: 86_400, engine: engine) }

    it 'returns success: true' do
      expect(runner.check_tide(engine: engine)[:success]).to be(true)
    end

    it 'returns level in [0, 1]' do
      level = runner.check_tide(engine: engine)[:level]
      expect(level).to be >= 0.0
      expect(level).to be <= 1.0
    end

    it 'returns a valid phase symbol' do
      phase = runner.check_tide(engine: engine)[:phase]
      expect(Legion::Extensions::CognitiveTide::Helpers::Constants::TIDE_PHASES).to include(phase)
    end

    it 'returns a string label' do
      expect(runner.check_tide(engine: engine)[:label]).to be_a(String)
    end

    it 'works with no oscillators (returns 0.0 level)' do
      empty_engine = Legion::Extensions::CognitiveTide::Helpers::TideEngine.new
      result = runner.check_tide(engine: empty_engine)
      expect(result[:success]).to be(true)
      expect(result[:level]).to eq(0.0)
    end
  end

  describe '.deposit_idea' do
    it 'deposits an idea and returns success: true' do
      result = runner.deposit_idea(domain: 'philosophy', idea: 'consciousness is emergent',
                                   engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns domain in response' do
      result = runner.deposit_idea(domain: 'test', idea: 'x', engine: engine)
      expect(result[:domain]).to eq('test')
    end

    it 'skips deposit when tide is above threshold' do
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: Math::PI / 2.0)
      result = runner.deposit_idea(domain: 'ideas', idea: 'blocked', tide_threshold: 0.1, engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:reason]).to eq(:tide_too_high)
    end

    it 'deposits when tide is below threshold' do
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: -Math::PI / 2.0)
      result = runner.deposit_idea(domain: 'ideas', idea: 'allowed', tide_threshold: 0.5, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'skips threshold check when tide_threshold is nil' do
      result = runner.deposit_idea(domain: 'ideas', idea: 'any tide', tide_threshold: nil, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'accepts ** splat kwargs' do
      result = runner.deposit_idea(domain: 'ideas', idea: 'test', extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '.harvest' do
    before do
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0)
      runner.deposit_idea(domain: 'ideas', idea: 'harvest me', engine: engine)
    end

    it 'returns success: true' do
      result = runner.harvest(engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns harvested hash and total_items count' do
      allow(engine).to receive(:rising?).and_return(true)
      result = runner.harvest(engine: engine)
      expect(result[:harvested]).to be_a(Hash)
      expect(result[:total_items]).to be_a(Integer)
    end

    it 'returns total_items: 0 when not rising' do
      allow(engine).to receive(:rising?).and_return(false)
      result = runner.harvest(engine: engine)
      expect(result[:total_items]).to eq(0)
    end

    it 'accepts min_depth kwarg' do
      allow(engine).to receive(:rising?).and_return(true)
      result = runner.harvest(min_depth: 0.99, engine: engine)
      expect(result[:success]).to be(true)
      # pool depth is well below 0.99, so nothing harvested
      expect(result[:total_items]).to eq(0)
    end

    it 'accepts ** splat kwargs' do
      result = runner.harvest(extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '.tide_forecast' do
    before { engine.add_oscillator(oscillator_type: :primary, period: 86_400) }

    it 'returns success: true' do
      result = runner.tide_forecast(duration: 3600, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns forecast array' do
      result = runner.tide_forecast(duration: 3600, engine: engine)
      expect(result[:forecast]).to be_an(Array)
    end

    it 'returns correct duration in response' do
      result = runner.tide_forecast(duration: 7200, engine: engine)
      expect(result[:duration]).to eq(7200)
    end

    it 'returns empty forecast for engine with no oscillators' do
      empty_engine = Legion::Extensions::CognitiveTide::Helpers::TideEngine.new
      result = runner.tide_forecast(duration: 3600, engine: empty_engine)
      expect(result[:forecast]).to eq([])
    end

    it 'accepts ** splat kwargs' do
      result = runner.tide_forecast(duration: 3600, extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '.tide_status' do
    before { engine.add_oscillator(oscillator_type: :primary, period: 86_400) }

    it 'returns success: true' do
      expect(runner.tide_status(engine: engine)[:success]).to be(true)
    end

    it 'includes tide report fields' do
      result = runner.tide_status(engine: engine)
      expect(result.keys).to include(:level, :phase, :label, :oscillator_count, :pool_count)
    end

    it 'returns oscillator_count matching registered oscillators' do
      expect(runner.tide_status(engine: engine)[:oscillator_count]).to eq(1)
    end

    it 'accepts ** splat kwargs' do
      result = runner.tide_status(extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end
end
