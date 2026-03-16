# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_tide/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-tide'
  spec.version       = Legion::Extensions::CognitiveTide::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX CognitiveTide'
  spec.description   = 'Circadian-like cognitive rhythm engine for brain-modeled agentic AI — ' \
                       'tidal oscillators, composite tide levels, and tidal pool idea accumulation'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-tide'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/LegionIO/lex-cognitive-tide'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-cognitive-tide'
  spec.metadata['changelog_uri']     = 'https://github.com/LegionIO/lex-cognitive-tide'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/LegionIO/lex-cognitive-tide/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-tide.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
