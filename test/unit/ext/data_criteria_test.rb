require 'test_helper'
require 'hqmf2js'

class DataCriteriaTest < MiniTest::Unit::TestCase
  def setup
    @all_data_criteria = MONGO_DB["data_criteria"].find({}).to_a
    @characteristic_criteria = @all_data_criteria.find_all { |dc| dc["property"].present? }
    @field_criteria = @all_data_criteria.find_all { |dc| dc["negation"] && dc["negation"].empty? }
    @negation_criteria = @all_data_criteria.find_all { |dc| dc["negation"].present? }
  end

  def test_modify_patient
    # measure_needs = {"1234" => @all_data_criteria}
    # HQMF::DataCriteria.modify_patient(measure_needs)
  end

  def test_modify_patient_with_characteristic
    
  end

  def test_derive_entry

  end

  def test_modify_entry_with_values

  end

  def test_modify_entry_with_negation

  end

  def test_modify_entry_with_fields

  end

  def test_modify_patient_with_entry
    
  end
end