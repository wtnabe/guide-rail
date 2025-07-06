# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "guide-rail"

require "minitest/autorun"
require "minitest/spec"
require "minitest-power_assert"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
