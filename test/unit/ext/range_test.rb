require 'test_helper'

class RangeTest < MiniTest::Unit::TestCase
  def test_format
    now = Time.at(1234567890).utc
    low = HQMF::Value.new("TS", nil, HQMF::Value.time_to_ts(now), true, false, false)

    later = now + (60 * 60 * 24 * 7)
    high = HQMF::Value.new("TS", nil, HQMF::Value.time_to_ts(later), true, false, false)

    range = HQMF::Range.new("IVL_TS", low, nil, 1)
    assert_equal 1234567890, range.format

    range = HQMF::Range.new("IVL_TS", nil, high, 1)
    assert_equal 1235172690, range.format
  end
end