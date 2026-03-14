# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveTide::Helpers::TidalPool do
  let(:pool) { described_class.new(domain: 'architecture', capacity: 5) }

  describe '#initialize' do
    it 'assigns domain as string' do
      expect(pool.domain).to eq('architecture')
    end

    it 'accepts symbol domain and converts to string' do
      p = described_class.new(domain: :philosophy)
      expect(p.domain).to eq('philosophy')
    end

    it 'assigns capacity' do
      expect(pool.capacity).to eq(5)
    end

    it 'starts empty' do
      expect(pool.size).to eq(0)
    end

    it 'starts with zero evaporation_count' do
      expect(pool.evaporation_count).to eq(0)
    end

    it 'generates a uuid id' do
      expect(pool.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'raises ArgumentError for non-positive capacity' do
      expect { described_class.new(domain: 'test', capacity: 0) }
        .to raise_error(ArgumentError, /capacity must be positive/)
    end

    it 'raises ArgumentError for negative capacity' do
      expect { described_class.new(domain: 'test', capacity: -1) }
        .to raise_error(ArgumentError, /capacity must be positive/)
    end
  end

  describe '#deposit' do
    it 'deposits an item and returns true' do
      result = pool.deposit('refactor auth layer')
      expect(result).to be(true)
      expect(pool.size).to eq(1)
    end

    it 'stores items with metadata' do
      pool.deposit('idea one')
      item = pool.items.first
      expect(item[:content]).to eq('idea one')
      expect(item[:deposited_at]).to be_a(Time)
      expect(item[:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns false when pool is full' do
      5.times { |i| pool.deposit("idea #{i}") }
      expect(pool.deposit('overflow')).to be(false)
    end

    it 'does not add item when full' do
      5.times { |i| pool.deposit("idea #{i}") }
      pool.deposit('overflow')
      expect(pool.size).to eq(5)
    end

    it 'accepts any object as item' do
      pool.deposit({ key: 'value' })
      pool.deposit(42)
      pool.deposit(:symbol)
      expect(pool.size).to eq(3)
    end
  end

  describe '#harvest!' do
    it 'returns all items' do
      pool.deposit('alpha')
      pool.deposit('beta')
      harvested = pool.harvest!
      expect(harvested.size).to eq(2)
      expect(harvested.map { |i| i[:content] }).to contain_exactly('alpha', 'beta')
    end

    it 'clears the pool after harvest' do
      pool.deposit('alpha')
      pool.harvest!
      expect(pool.size).to eq(0)
    end

    it 'returns empty array when pool is empty' do
      expect(pool.harvest!).to eq([])
    end
  end

  describe '#evaporate!' do
    let(:large_pool) { described_class.new(domain: 'test', capacity: 20) }

    before { 10.times { |i| large_pool.deposit("item #{i}") } }

    it 'removes a proportion of items (oldest first)' do
      large_pool.evaporate!(0.2)
      # ceil(10 * 0.2) = 2 removed
      expect(large_pool.size).to eq(8)
    end

    it 'increments evaporation_count' do
      large_pool.evaporate!(0.3)
      expect(large_pool.evaporation_count).to be > 0
    end

    it 'returns the number of items removed' do
      removed = large_pool.evaporate!(0.1)
      expect(removed).to eq(1)
    end

    it 'clamps rate at 1.0 and removes all items' do
      large_pool.evaporate!(2.0)
      expect(large_pool.size).to eq(0)
    end

    it 'clamps rate at 0.0 and removes nothing' do
      large_pool.evaporate!(-0.5)
      expect(large_pool.size).to eq(10)
    end

    it 'uses POOL_EVAPORATION_RATE when no argument given' do
      # 0.01 rate on 10 items: ceil(0.1) = 1 removed
      removed = large_pool.evaporate!
      expect(removed).to eq(1)
      expect(large_pool.size).to eq(9)
    end
  end

  describe '#full?' do
    it 'returns false when below capacity' do
      expect(pool.full?).to be(false)
    end

    it 'returns true when at capacity' do
      5.times { |i| pool.deposit("item #{i}") }
      expect(pool.full?).to be(true)
    end
  end

  describe '#depth' do
    it 'returns 0.0 when empty' do
      expect(pool.depth).to eq(0.0)
    end

    it 'returns 1.0 when full' do
      5.times { |i| pool.deposit("item #{i}") }
      expect(pool.depth).to eq(1.0)
    end

    it 'returns fractional depth' do
      pool.deposit('one')
      pool.deposit('two')
      expect(pool.depth).to be_within(0.001).of(0.4)
    end

    it 'rounds to 10 decimal places' do
      pool.deposit('one')
      expect(pool.depth).to eq(pool.depth.round(10))
    end
  end

  describe '#items' do
    it 'returns a copy of items (not the internal array)' do
      pool.deposit('item')
      items = pool.items
      items.clear
      expect(pool.size).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = pool.to_h
      expect(h.keys).to include(:id, :domain, :capacity, :size, :depth, :evaporation_count, :created_at)
    end

    it 'size reflects current item count' do
      pool.deposit('x')
      expect(pool.to_h[:size]).to eq(1)
    end

    it 'created_at is a Time' do
      expect(pool.to_h[:created_at]).to be_a(Time)
    end
  end
end
