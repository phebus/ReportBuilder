require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
  add_filter 'vendor'
end

require 'report_builder'
require 'report_builder/feature'
require 'report_builder/input'
require 'tempfile'
require 'rspec_junit_formatter'

here = File.dirname(__FILE__)
TEST_FIXTURES_DIRECTORY = "#{here}/fixtures".freeze
BIN_DIRECTORY = "#{here}/../bin".freeze

require_relative "#{here}/file_helper"

RSpec.configure do |config|
  # Ensure that we read in our test files the same on all platforms
  Encoding.default_external = 'UTF-8'

  config.after(:all) do
    ReportBuilder::FileHelper.clear_created_directories
  end
end
