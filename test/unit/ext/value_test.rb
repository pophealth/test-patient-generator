require 'test_helper'

class ValueTest < MiniTest::Unit::TestCase
  def setup
    @now = Time.at(1234567890)
    @ts = HQMF::Value.new("TS", nil, HQMF::Value.time_to_ts(@now), true, false, false)
    @pq = HQMF::Value.new("PQ", 'a', 10, true, false, false)
  end

  def test_time_to_ts
    assert_equal "20090213", HQMF::Value.time_to_ts(@now)
  end

  def test_format
    formatted_pq = { "scalar" => '10', "units" => 'a' }
    assert_equal formatted_pq, @pq.format
    binding.pry
    assert_equal 1234567890, @ts.format
  end

  def test_to_seconds
    assert_equal 1234567890, @ts.to_seconds
    assert_nil pq.to_seconds
  end

  def test_to_time_object
    assert_equal @now, @ts.to_time_object
  end
end