# frozen_string_literal: true

require 'legion/extensions/cognitive_tide/helpers/constants'
require 'legion/extensions/cognitive_tide/helpers/oscillator'
require 'legion/extensions/cognitive_tide/helpers/tidal_pool'
require 'legion/extensions/cognitive_tide/helpers/tide_engine'
require 'legion/extensions/cognitive_tide/runners/cognitive_tide'

module Legion
  module Extensions
    module CognitiveTide
      class Client
        include Runners::CognitiveTide

        def initialize(**)
          @tide_engine = Helpers::TideEngine.new
        end

        private

        attr_reader :tide_engine
      end
    end
  end
end
