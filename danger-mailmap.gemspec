# frozen_string_literal: true

require_relative 'lib/mailmap/gem_version'

Gem::Specification.new do |spec|
  spec.name = 'danger-mailmap'
  spec.version = Mailmap::VERSION
  spec.authors = ['Ryosuke Ito']
  spec.email = ['rito.0305@gmail.com']
  spec.description = 'A Danger plugin to check if .mailmap has a canonical name of author and commiter'
  spec.summary = spec.description
  spec.homepage = 'https://github.com/manicmaniac/danger-mailmap'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.add_dependency 'danger-plugin-api', '~> 1.0'
end
