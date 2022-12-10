# frozen_string_literal: true

ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.join(ROOT, 'lib'), File.join(ROOT, 'spec'))

require 'danger'
require 'pry'
require 'rspec'

RSpec.configure do |config|
  config.filter_gems_from_backtrace 'bundler'
end

require 'danger_plugin'
require 'support/helpers'
