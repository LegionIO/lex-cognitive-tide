# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveTide
      module Runners
        module CognitiveTide
          extend self

          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def add_oscillator(oscillator_type: :primary, period: 86_400, amplitude: 1.0,
                             phase_offset: 0.0, engine: nil, **)
            eng = engine || tide_engine
            osc = eng.add_oscillator(
              oscillator_type: oscillator_type.to_sym,
              period:          period,
              amplitude:       amplitude,
              phase_offset:    phase_offset
            )
            Legion::Logging.debug "[cognitive_tide] oscillator added: type=#{oscillator_type} " \
                                  "period=#{period} amplitude=#{amplitude}"
            { success: true, oscillator: osc.to_h }
          rescue ArgumentError => e
            Legion::Logging.error "[cognitive_tide] add_oscillator failed: #{e.message}"
            { success: false, error: e.message }
          end

          def check_tide(engine: nil, **)
            eng   = engine || tide_engine
            level = eng.composite_tide_level
            phase = eng.current_phase
            label = Helpers::Constants::TIDE_LABELS.find { |tl| tl[:range].cover?(level) }&.fetch(:label, 'ebb')
            Legion::Logging.debug "[cognitive_tide] check_tide: level=#{level.round(3)} phase=#{phase} label=#{label}"
            {
              success: true,
              level:   level,
              phase:   phase,
              label:   label
            }
          rescue ArgumentError => e
            Legion::Logging.error "[cognitive_tide] check_tide failed: #{e.message}"
            { success: false, error: e.message }
          end

          def deposit_idea(domain:, idea:, capacity: 20, tide_threshold: nil, engine: nil, **)
            eng = engine || tide_engine

            if tide_threshold
              level = eng.composite_tide_level
              if level > tide_threshold
                Legion::Logging.debug "[cognitive_tide] deposit_idea skipped: tide=#{level.round(3)} above threshold=#{tide_threshold}"
                return { success: false, reason: :tide_too_high, level: level }
              end
            end

            deposited = eng.deposit_to_pool(domain: domain, item: idea, capacity: capacity)
            Legion::Logging.debug "[cognitive_tide] deposit_idea: domain=#{domain} deposited=#{deposited}"
            { success: deposited, domain: domain }
          rescue ArgumentError => e
            Legion::Logging.error "[cognitive_tide] deposit_idea failed: #{e.message}"
            { success: false, error: e.message }
          end

          def harvest(min_depth: 0.0, engine: nil, **)
            eng    = engine || tide_engine
            result = eng.harvest_pools(min_depth: min_depth.to_f)
            total  = result.values.sum(&:size)
            Legion::Logging.debug "[cognitive_tide] harvest: domains=#{result.keys.size} total_items=#{total}"
            { success: true, harvested: result, total_items: total }
          rescue ArgumentError => e
            Legion::Logging.error "[cognitive_tide] harvest failed: #{e.message}"
            { success: false, error: e.message }
          end

          def tide_forecast(duration: 86_400, engine: nil, **)
            eng      = engine || tide_engine
            forecast = eng.tide_forecast(duration)
            Legion::Logging.debug "[cognitive_tide] tide_forecast: duration=#{duration} steps=#{forecast.size}"
            { success: true, forecast: forecast, duration: duration }
          rescue ArgumentError => e
            Legion::Logging.error "[cognitive_tide] tide_forecast failed: #{e.message}"
            { success: false, error: e.message }
          end

          def tide_status(engine: nil, **)
            eng    = engine || tide_engine
            report = eng.tide_report
            Legion::Logging.debug "[cognitive_tide] tide_status: level=#{report[:level].round(3)} " \
                                  "phase=#{report[:phase]} pools=#{report[:pool_count]}"
            report.merge(success: true)
          rescue ArgumentError => e
            Legion::Logging.error "[cognitive_tide] tide_status failed: #{e.message}"
            { success: false, error: e.message }
          end

          def tide_maintenance(engine: nil, **)
            eng = engine || tide_engine
            eng.evaporate_all!
            eng.oscillators.each(&:tick!)
            pools_maintained = eng.pools.size
            phase            = eng.current_phase
            level            = eng.composite_tide_level
            Legion::Logging.debug "[tide] maintenance: pools=#{pools_maintained} phase=#{phase} level=#{level}"
            { pools_maintained: pools_maintained, current_phase: phase, tide_level: level }
          end

          private

          def tide_engine
            @tide_engine ||= Helpers::TideEngine.new
          end
        end
      end
    end
  end
end
