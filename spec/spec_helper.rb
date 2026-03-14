# frozen_string_literal: true

require 'bundler/setup'

module Legion
  module Logging
    def self.debug(_msg); end
    def self.info(_msg); end
    def self.warn(_msg); end
    def self.error(_msg); end
  end

  module Extensions
    module Helpers
      module Lex; end
    end
  end
end

require 'legion/extensions/cognitive_tide'
require 'legion/extensions/cognitive_tide/client'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
