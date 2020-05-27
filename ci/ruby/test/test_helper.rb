require 'minitest/autorun'

require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'webmock/minitest'
WebMock.disable_net_connect!
