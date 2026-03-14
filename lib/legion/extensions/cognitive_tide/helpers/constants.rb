# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveTide
      module Helpers
        module Constants
          TIDE_PHASES = %i[rising high_tide falling low_tide].freeze
          OSCILLATOR_TYPES = %i[primary secondary lunar].freeze

          MAX_POOLS = 50
          POOL_EVAPORATION_RATE = 0.01

          # Range-based tide label lookup — ranges are ordered from highest to lowest
          TIDE_LABELS = [
            { range: (0.85..1.0),   label: 'peak' },
            { range: (0.65..0.85),  label: 'high' },
            { range: (0.45..0.65),  label: 'moderate' },
            { range: (0.25..0.45),  label: 'low' },
            { range: (0.0..0.25),   label: 'ebb' }
          ].freeze

          # Spring tide threshold: two oscillators are considered in phase when their values
          # differ by less than this proportion of their combined amplitude
          SPRING_TIDE_PHASE_TOLERANCE = 0.15

          # Minimum tide level above which harvest is permitted
          HARVEST_RISING_THRESHOLD = 0.3

          # Forecast resolution: seconds between each forecast sample
          FORECAST_RESOLUTION = 300
        end
      end
    end
  end
end
