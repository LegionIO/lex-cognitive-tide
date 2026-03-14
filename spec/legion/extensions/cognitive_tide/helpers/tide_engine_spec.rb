# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveTide::Helpers::TideEngine do
  let(:engine) { described_class.new }

  def add_primary(eng = engine, amplitude: 1.0)
    eng.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: amplitude)
  end

  def add_secondary(eng = engine, amplitude: 0.5)
    eng.add_oscillator(oscillator_type: :secondary, period: 43_200, amplitude: amplitude)
  end

  describe '#initialize' do
    it 'starts with no oscillators' do
      expect(engine.oscillators).to be_empty
    end

    it 'starts with no pools' do
      expect(engine.pools).to be_empty
    end
  end

  describe '#add_oscillator' do
    it 'returns an Oscillator instance' do
      osc = add_primary
      expect(osc).to be_a(Legion::Extensions::CognitiveTide::Helpers::Oscillator)
    end

    it 'appends to oscillators' do
      add_primary
      expect(engine.oscillators.size).to eq(1)
    end

    it 'allows multiple oscillators' do
      add_primary
      add_secondary
      expect(engine.oscillators.size).to eq(2)
    end

    it 'raises ArgumentError for unknown oscillator_type' do
      expect { engine.add_oscillator(oscillator_type: :invalid, period: 3600) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#composite_tide_level' do
    it 'returns 0.0 with no oscillators' do
      expect(engine.composite_tide_level).to eq(0.0)
    end

    it 'returns a value in [0, 1]' do
      add_primary
      add_secondary
      level = engine.composite_tide_level
      expect(level).to be >= 0.0
      expect(level).to be <= 1.0
    end

    it 'is deterministic for the same time' do
      t = Time.utc(2026, 1, 1, 12, 0, 0)
      allow(Time).to receive(:now).and_return(t)
      add_primary
      expect(engine.composite_tide_level).to eq(engine.composite_tide_level)
    end

    it 'returns 0.0 when all amplitudes are 0' do
      engine.add_oscillator(oscillator_type: :primary, period: 3600, amplitude: 0.0)
      expect(engine.composite_tide_level).to eq(0.0)
    end

    it 'respects amplitude weighting with a single oscillator' do
      eng = described_class.new
      eng.add_oscillator(oscillator_type: :primary, period: 3600, amplitude: 1.0, phase_offset: 0.0)
      level = eng.composite_tide_level
      expect(level).to be >= 0.0
      expect(level).to be <= 1.0
    end
  end

  describe '#current_phase' do
    it 'returns one of the four tide phases' do
      add_primary
      expect(Legion::Extensions::CognitiveTide::Helpers::Constants::TIDE_PHASES)
        .to include(engine.current_phase)
    end

    it 'returns :high_tide when level >= 0.65' do
      # Force high level: sin at peak with phase_offset = PI/2, at t=0
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      # phase_offset = PI/2 means sin = 1.0 at t=0
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: Math::PI / 2.0)
      expect(engine.current_phase).to eq(:high_tide)
    end

    it 'returns :low_tide when level <= 0.35' do
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      # phase_offset = -PI/2 means sin = -1.0 at t=0 → value_at = 0.0
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: -Math::PI / 2.0)
      expect(engine.current_phase).to eq(:low_tide)
    end
  end

  describe '#create_pool' do
    it 'creates a pool for a domain' do
      pool = engine.create_pool(domain: 'philosophy')
      expect(pool).to be_a(Legion::Extensions::CognitiveTide::Helpers::TidalPool)
      expect(pool.domain).to eq('philosophy')
    end

    it 'appends to pools' do
      engine.create_pool(domain: 'philosophy')
      expect(engine.pools.size).to eq(1)
    end

    it 'returns existing pool if domain already exists' do
      p1 = engine.create_pool(domain: 'ideas')
      p2 = engine.create_pool(domain: 'ideas')
      expect(p1.id).to eq(p2.id)
      expect(engine.pools.size).to eq(1)
    end

    it 'returns nil when MAX_POOLS is reached' do
      max = Legion::Extensions::CognitiveTide::Helpers::Constants::MAX_POOLS
      max.times { |i| engine.create_pool(domain: "domain_#{i}") }
      result = engine.create_pool(domain: 'overflow')
      expect(result).to be_nil
    end

    it 'does not add a pool when at capacity' do
      max = Legion::Extensions::CognitiveTide::Helpers::Constants::MAX_POOLS
      max.times { |i| engine.create_pool(domain: "domain_#{i}") }
      engine.create_pool(domain: 'overflow')
      expect(engine.pools.size).to eq(max)
    end
  end

  describe '#deposit_to_pool' do
    it 'deposits an item into a new domain pool' do
      result = engine.deposit_to_pool(domain: 'ideas', item: 'refactor this')
      expect(result).to be(true)
    end

    it 'auto-creates the pool if not present' do
      engine.deposit_to_pool(domain: 'fresh_domain', item: 'test idea')
      expect(engine.pools.size).to eq(1)
    end

    it 'deposits into existing pool for domain' do
      engine.deposit_to_pool(domain: 'ideas', item: 'idea 1')
      engine.deposit_to_pool(domain: 'ideas', item: 'idea 2')
      pool = engine.pools.first
      expect(pool.size).to eq(2)
    end

    it 'returns false when MAX_POOLS is reached and domain is new' do
      max = Legion::Extensions::CognitiveTide::Helpers::Constants::MAX_POOLS
      max.times { |i| engine.create_pool(domain: "domain_#{i}") }
      result = engine.deposit_to_pool(domain: 'overflow', item: 'idea')
      expect(result).to be(false)
    end
  end

  describe '#harvest_pools' do
    before do
      add_primary
      engine.deposit_to_pool(domain: 'ideas', item: 'alpha')
      engine.deposit_to_pool(domain: 'ideas', item: 'beta')
    end

    it 'returns empty hash when tide is not rising' do
      # Make the engine report non-rising phase
      allow(engine).to receive(:rising?).and_return(false)
      expect(engine.harvest_pools).to eq({})
    end

    it 'returns harvested items by domain when rising' do
      allow(engine).to receive(:rising?).and_return(true)
      result = engine.harvest_pools
      expect(result).to have_key('ideas')
      expect(result['ideas'].size).to eq(2)
    end

    it 'clears pools after harvest' do
      allow(engine).to receive(:rising?).and_return(true)
      engine.harvest_pools
      expect(engine.pools.first.size).to eq(0)
    end

    it 'respects min_depth threshold' do
      allow(engine).to receive(:rising?).and_return(true)
      # Pool has 2 items with capacity 20 → depth = 0.1; skip pools below 0.5
      result = engine.harvest_pools(min_depth: 0.5)
      expect(result).not_to have_key('ideas')
    end

    it 'skips empty pools' do
      allow(engine).to receive(:rising?).and_return(true)
      engine.create_pool(domain: 'empty_pool')
      result = engine.harvest_pools
      expect(result).not_to have_key('empty_pool')
    end
  end

  describe '#evaporate_all!' do
    it 'returns total items removed across all pools' do
      20.times { |i| engine.deposit_to_pool(domain: 'ideas', item: "idea #{i}") }
      removed = engine.evaporate_all!(0.1)
      expect(removed).to be > 0
    end

    it 'evaporates all pools' do
      engine.deposit_to_pool(domain: 'alpha', item: 'idea a')
      engine.deposit_to_pool(domain: 'beta', item: 'idea b')
      removed = engine.evaporate_all!(1.0)
      expect(removed).to eq(2)
    end

    it 'returns 0 when no pools' do
      expect(engine.evaporate_all!).to eq(0)
    end
  end

  describe '#tide_forecast' do
    it 'returns empty array with no oscillators' do
      expect(engine.tide_forecast(3600)).to eq([])
    end

    it 'returns forecast entries for duration' do
      add_primary
      forecast = engine.tide_forecast(3600)
      expect(forecast).not_to be_empty
    end

    it 'each entry has time, level, and label' do
      add_primary
      entry = engine.tide_forecast(3600).first
      expect(entry[:time]).to be_a(Time)
      expect(entry[:level]).to be_between(0.0, 1.0)
      expect(entry[:label]).to be_a(String)
    end

    it 'number of steps is ceil(duration / FORECAST_RESOLUTION)' do
      resolution = Legion::Extensions::CognitiveTide::Helpers::Constants::FORECAST_RESOLUTION
      add_primary
      steps = engine.tide_forecast(resolution * 4).size
      expect(steps).to eq(4)
    end
  end

  describe '#high_tide?' do
    it 'returns true when level >= 0.65' do
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: Math::PI / 2.0)
      expect(engine.high_tide?).to be(true)
    end

    it 'returns false when level < 0.65' do
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: -Math::PI / 2.0)
      expect(engine.high_tide?).to be(false)
    end
  end

  describe '#low_tide?' do
    it 'returns true when level <= 0.35' do
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: -Math::PI / 2.0)
      expect(engine.low_tide?).to be(true)
    end

    it 'returns false when level > 0.35' do
      t = Time.utc(2026, 1, 1)
      allow(Time).to receive(:now).and_return(t)
      engine.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                            phase_offset: Math::PI / 2.0)
      expect(engine.low_tide?).to be(false)
    end
  end

  describe '#tide_report' do
    it 'returns a hash with expected keys' do
      add_primary
      report = engine.tide_report
      expect(report.keys).to include(:level, :phase, :label, :oscillator_count, :pool_count,
                                     :high_tide, :low_tide, :pools, :oscillators)
    end

    it 'oscillator_count matches registered oscillators' do
      add_primary
      add_secondary
      expect(engine.tide_report[:oscillator_count]).to eq(2)
    end

    it 'pool_count matches created pools' do
      engine.create_pool(domain: 'alpha')
      engine.create_pool(domain: 'beta')
      expect(engine.tide_report[:pool_count]).to eq(2)
    end

    it 'pools is an array of pool hashes' do
      engine.create_pool(domain: 'phi')
      pools = engine.tide_report[:pools]
      expect(pools).to be_an(Array)
      expect(pools.first).to be_a(Hash)
    end

    it 'oscillators is an array of oscillator hashes' do
      add_primary
      osc_list = engine.tide_report[:oscillators]
      expect(osc_list).to be_an(Array)
      expect(osc_list.first).to be_a(Hash)
    end
  end
end
