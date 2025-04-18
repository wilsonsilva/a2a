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

  spec.add_dependency 'dry-struct', '~> 1.8'
  spec.add_dependency 'zeitwerk', '~> 2.7'
end
