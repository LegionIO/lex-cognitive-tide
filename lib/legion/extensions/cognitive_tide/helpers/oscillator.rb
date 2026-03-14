# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveTide
      module Helpers
        class Oscillator
          attr_reader :oscillator_type, :period, :amplitude, :phase_offset, :id

          def initialize(oscillator_type:, period:, amplitude: 1.0, phase_offset: 0.0)
            unless Constants::OSCILLATOR_TYPES.include?(oscillator_type)
              raise ArgumentError, "unknown oscillator_type: #{oscillator_type.inspect}; " \
                                   "must be one of #{Constants::OSCILLATOR_TYPES.inspect}"
            end

            raise ArgumentError, 'period must be positive' unless period.positive?

            @id = SecureRandom.uuid
            @oscillator_type = oscillator_type
            @period         = period.to_f
            @amplitude      = amplitude.clamp(0.0, 1.0)
            @phase_offset   = phase_offset.to_f
            @last_ticked_at = nil
          end

          # Advance the oscillator by computing its current sinusoidal value
          def tick!
            @last_ticked_at = Time.now.utc
            current_value
          end

          # Sinusoidal value at a given time, normalized to [0, 1]
          def value_at(time)
            t = time.to_f
            radians = ((2.0 * Math::PI * t) / @period) + @phase_offset
            # sin ranges [-1, 1] — shift to [0, 1]
            ((Math.sin(radians) + 1.0) / 2.0 * @amplitude).round(10)
          end

          # Current value based on Time.now
          def current_value
            value_at(Time.now.utc)
          end

          # Two oscillators are in phase when their normalized values are within tolerance
          def in_phase_with?(other)
            combined_amplitude = [@amplitude, other.amplitude].sum
            return false if combined_amplitude.zero?

            tolerance = Constants::SPRING_TIDE_PHASE_TOLERANCE * combined_amplitude
            (current_value - other.current_value).abs <= tolerance
          end

          def to_h
            {
              id:              @id,
              oscillator_type: @oscillator_type,
              period:          @period,
              amplitude:       @amplitude,
              phase_offset:    @phase_offset,
              current_value:   current_value,
              last_ticked_at:  @last_ticked_at
            }
          end
        end
      end
    end
  end
end
