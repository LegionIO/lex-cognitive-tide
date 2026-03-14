# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveTide
      module Helpers
        class TideEngine
          attr_reader :oscillators, :pools

          def initialize
            @oscillators = []
            @pools       = []
          end

          # Add an oscillator; returns the new Oscillator instance
          def add_oscillator(oscillator_type:, period:, amplitude: 1.0, phase_offset: 0.0)
            osc = Oscillator.new(
              oscillator_type: oscillator_type,
              period:          period,
              amplitude:       amplitude,
              phase_offset:    phase_offset
            )
            @oscillators << osc
            osc
          end

          # Composite tide level: clamped sum of all oscillator current values, normalized to [0, 1]
          def composite_tide_level
            return 0.0 if @oscillators.empty?

            raw = @oscillators.sum(&:current_value)
            max = @oscillators.sum(&:amplitude)
            return 0.0 if max.zero?

            (raw / max).clamp(0.0, 1.0).round(10)
          end

          # Determine phase based on comparison of current and recent tide level
          def current_phase
            level = composite_tide_level
            previous = previous_level

            if level >= 0.65
              :high_tide
            elsif level <= 0.35
              :low_tide
            elsif level > previous
              :rising
            else
              :falling
            end
          end

          # Create a new tidal pool for a domain; respects MAX_POOLS limit
          def create_pool(domain:, capacity: 20)
            return nil if @pools.size >= Constants::MAX_POOLS

            existing = find_pool(domain)
            return existing if existing

            pool = TidalPool.new(domain: domain, capacity: capacity)
            @pools << pool
            pool
          end

          # Deposit an item into a domain pool (creates the pool if needed)
          def deposit_to_pool(domain:, item:, capacity: 20)
            pool = find_pool(domain) || create_pool(domain: domain, capacity: capacity)
            return false unless pool

            pool.deposit(item)
          end

          # Harvest pools only when tide is rising; returns hash of domain => items
          def harvest_pools(min_depth: 0.0)
            return {} unless rising?

            result = {}
            @pools.each do |pool|
              next if pool.depth < min_depth
              next if pool.empty?

              result[pool.domain] = pool.harvest!
            end
            result
          end

          # Apply evaporation to all pools
          def evaporate_all!(rate = Constants::POOL_EVAPORATION_RATE)
            @pools.sum { |pool| pool.evaporate!(rate) }
          end

          # Forecast tide level at regular intervals over a duration (seconds)
          def tide_forecast(duration)
            return [] if @oscillators.empty?

            steps = (duration.to_f / Constants::FORECAST_RESOLUTION).ceil
            now   = Time.now.utc

            (0...steps).map do |step|
              t     = now + (step * Constants::FORECAST_RESOLUTION)
              level = forecast_level_at(t)
              { time: t, level: level, label: tide_label(level) }
            end
          end

          def high_tide?
            composite_tide_level >= 0.65
          end

          def low_tide?
            composite_tide_level <= 0.35
          end

          def rising?
            current_phase == :rising
          end

          def tide_report
            level = composite_tide_level
            {
              level:            level,
              phase:            current_phase,
              label:            tide_label(level),
              oscillator_count: @oscillators.size,
              pool_count:       @pools.size,
              high_tide:        high_tide?,
              low_tide:         low_tide?,
              pools:            @pools.map(&:to_h),
              oscillators:      @oscillators.map(&:to_h)
            }
          end

          private

          def find_pool(domain)
            @pools.find { |p| p.domain == domain.to_s }
          end

          def previous_level
            return 0.0 if @oscillators.empty?

            t   = Time.now.utc - Constants::FORECAST_RESOLUTION
            raw = @oscillators.sum { |osc| osc.value_at(t) }
            max = @oscillators.sum(&:amplitude)
            return 0.0 if max.zero?

            (raw / max).clamp(0.0, 1.0)
          end

          def forecast_level_at(time)
            raw = @oscillators.sum { |osc| osc.value_at(time) }
            max = @oscillators.sum(&:amplitude)
            return 0.0 if max.zero?

            (raw / max).clamp(0.0, 1.0).round(10)
          end

          def tide_label(level)
            entry = Constants::TIDE_LABELS.find { |tl| tl[:range].cover?(level) }
            entry ? entry[:label] : 'ebb'
          end
        end
      end
    end
  end
end
