# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:specs)
RuboCop::RakeTask.new(:rubocop)

task default: :specs
task spec: %i[specs rubocop spec_docs]

desc 'Ensure that the plugin passes `danger plugins lint`'
task :spec_docs do
  sh 'danger plugins lint'
end
