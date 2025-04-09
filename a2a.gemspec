# frozen_string_literal: true

require_relative 'lib/a2a/version'

Gem::Specification.new do |spec|
  spec.name = 'a2a'
  spec.version = A2A::VERSION
  spec.authors = ['Wilson Silva']
  spec.email = ['wilson.dsigns@gmail.com']

  spec.summary = 'Implementation of the A2A (Agent2Agent) protocol.'
  spec.description = 'An open protocol enabling communication and interoperability between opaque agentic applications.'
  spec.homepage = 'https://github.com/wilsonsilva/a2a'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/wilsonsilva/a2a'
  spec.metadata['changelog_uri'] = 'https://github.com/wilsonsilva/a2a/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ spec/ .git .github Gemfile])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'guard', '~> 2.19'
  spec.add_development_dependency 'guard-bundler', '~> 3.0'
  spec.add_development_dependency 'guard-bundler-audit', '~> 0.1'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'guard-rubocop', '~> 1.5'
  spec.add_development_dependency 'irb', '~> 1.15.2'
  spec.add_development_dependency 'overcommit', '~> 0.67'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'rbs', '~> 3.8'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.75.2'
  spec.add_development_dependency 'rubocop-performance', '~> 1.25.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.7'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop-yard', '~> 0.10'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov-console', '~> 0.9'
  spec.add_development_dependency 'simplecov_json_formatter', '~> 0.1'
  spec.add_development_dependency 'steep', '~> 1.10'
  spec.add_development_dependency 'typeprof', '~> 0.30'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-junk', '~> 0.0'
  spec.add_development_dependency 'yardstick', '~> 0.9'
end
