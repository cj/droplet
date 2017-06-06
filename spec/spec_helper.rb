$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "droplet"
require "minitest/autorun"
require "minitest/reporters"
require "minitest/line/describe_track"

module Minitest
  class Spec
    class << self
      alias context describe
    end
  end
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
