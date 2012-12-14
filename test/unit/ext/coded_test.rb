require 'test_helper'

class CodedTest < MiniTest::Unit::TestCase
  # def setup
  #   value_sets_path = File.join('test', 'fixtures', 'value_sets', 'multiple_fields.json')
  #   value_sets = File.open(value_sets_path).read
  #   @value_sets = JSON.parse(value_sets)
  # end

  # def test_select_code
  #   codes = HQMF::Coded.select_codes("2.16.840.1.113883.3.117.1.7.1.23", @value_sets)
  #   assert_equal codes["Fake1"], ["12345"]
  #   assert_equal codes["Fake2"], ["6789"]
  # end

  # def test_select_value_sets
  #   matching_value_set = HQMF::Coded.select_value_sets("2.16.840.1.113883.3.117.1.7.1.23", @value_sets)
  #   assert_equal matching_value_set["oid"], "2.16.840.1.113883.3.117.1.7.1.23"
  # end

  # def test_select_codes
  #   codes = HQMF::Coded.select_code("2.16.840.1.113883.3.117.1.7.1.23", @value_sets)
  #   assert_equal codes["codeSystem"], "Fake1"
  #   assert_equal codes["code"], "12345"
  # end
end