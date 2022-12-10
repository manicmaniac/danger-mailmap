# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

task default: :spec

desc 'Run all linters'
task lint: %I[rubocop lint_docs]

desc 'Ensure that the plugin passes `danger plugins lint`'
task :lint_docs do
  sh 'danger plugins lint'
end
