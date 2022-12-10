# frozen_string_literal: true

ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.join(ROOT, 'lib'), File.join(ROOT, 'spec'))

require 'danger'
require 'pry'
require 'rspec'
require 'simplecov'
SimpleCov.start do
  load_profile 'test_frameworks'
  enable_coverage :branch
end
require 'danger_plugin'
require 'support/helpers'
