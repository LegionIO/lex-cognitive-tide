# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveTide::Client do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a new client' do
      expect(client).to be_a(described_class)
    end

    it 'responds to runner methods' do
      expect(client).to respond_to(:add_oscillator)
      expect(client).to respond_to(:check_tide)
      expect(client).to respond_to(:deposit_idea)
      expect(client).to respond_to(:harvest)
      expect(client).to respond_to(:tide_forecast)
      expect(client).to respond_to(:tide_status)
    end
  end

  describe 'full lifecycle' do
    it 'adds oscillators, deposits ideas, and harvests on rising tide' do
      # Add two oscillators
      r1 = client.add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0)
      r2 = client.add_oscillator(oscillator_type: :secondary, period: 43_200, amplitude: 0.5)
      expect(r1[:success]).to be(true)
      expect(r2[:success]).to be(true)

      # Deposit ideas
      d1 = client.deposit_idea(domain: 'architecture', idea: 'refactor auth module')
      d2 = client.deposit_idea(domain: 'architecture', idea: 'simplify routing layer')
      d3 = client.deposit_idea(domain: 'testing', idea: 'add integration specs')
      expect(d1[:success]).to be(true)
      expect(d2[:success]).to be(true)
      expect(d3[:success]).to be(true)

      # Check tide
      tide = client.check_tide
      expect(tide[:level]).to be_between(0.0, 1.0)
      expect(tide[:phase]).to be_a(Symbol)

      # Harvest (result depends on rising? state, but should not error)
      harvest = client.harvest
      expect(harvest[:success]).to be(true)
      expect(harvest[:harvested]).to be_a(Hash)

      # Status
      status = client.tide_status
      expect(status[:oscillator_count]).to eq(2)
      expect(status[:success]).to be(true)
    end

    it 'forecasts the tide for a given duration' do
      client.add_oscillator(oscillator_type: :lunar, period: 2_551_443, amplitude: 0.8)
      result = client.tide_forecast(duration: 86_400)
      expect(result[:success]).to be(true)
      expect(result[:forecast]).to be_an(Array)
      expect(result[:forecast]).not_to be_empty
    end

    it 'tidal pools accumulate ideas independently per domain' do
      client.add_oscillator(oscillator_type: :primary, period: 86_400)
      %w[alpha beta gamma].each do |domain|
        3.times { |i| client.deposit_idea(domain: domain, idea: "idea #{i} in #{domain}") }
      end
      status = client.tide_status
      expect(status[:pool_count]).to eq(3)
    end

    it 'returns the same engine state across calls' do
      client.add_oscillator(oscillator_type: :primary, period: 86_400)
      status_a = client.tide_status
      status_b = client.tide_status
      expect(status_a[:oscillator_count]).to eq(status_b[:oscillator_count])
    end
  end

  describe 'error handling' do
    it 'returns success: false for invalid oscillator_type without raising' do
      result = client.add_oscillator(oscillator_type: :bogus, period: 3600)
      expect(result[:success]).to be(false)
      expect(result[:error]).to be_a(String)
    end

    it 'returns success: false for non-positive period without raising' do
      result = client.add_oscillator(oscillator_type: :primary, period: -1)
      expect(result[:success]).to be(false)
    end
  end
end
