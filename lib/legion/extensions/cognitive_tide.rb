# frozen_string_literal: true

require 'securerandom'
require_relative 'cognitive_tide/version'
require_relative 'cognitive_tide/helpers/constants'
require_relative 'cognitive_tide/helpers/oscillator'
require_relative 'cognitive_tide/helpers/tidal_pool'
require_relative 'cognitive_tide/helpers/tide_engine'
require_relative 'cognitive_tide/runners/cognitive_tide'

module Legion
  module Extensions
    module CognitiveTide
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
