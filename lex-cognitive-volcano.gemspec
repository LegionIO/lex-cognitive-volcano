# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_volcano/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-volcano'
  spec.version       = Legion::Extensions::CognitiveVolcano::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Volcano'
  spec.description   = 'Models cognitive pressure buildup and eruption cycles — suppressed thoughts accumulate ' \
                       'pressure (like magma) until they erupt as breakthroughs, emotional outbursts, or creative explosions'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-volcano'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/LegionIO/lex-cognitive-volcano'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-cognitive-volcano'
  spec.metadata['changelog_uri']     = 'https://github.com/LegionIO/lex-cognitive-volcano'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/LegionIO/lex-cognitive-volcano/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
