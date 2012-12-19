require 'test_helper'
require 'hqmf2js'

class DataCriteriaTest < MiniTest::Unit::TestCase
  def setup
    binding.pry
    @all_data_criteria = MONGO_DB["data_criteria"].find({}).to_a.map { |data_criteria| HQMF::Document.from_json(self) }
    @time = Randomizer.randomize_range(nil, nil)

    oids = HQMF::Generator.select_unique_oids(@all_data_criteria)
    @value_sets = HQMF::Generator.create_oid_dictionary(oids)
  end

  def test_modify_patient
    patient = HQMF::Generator.create_base_patient

    @all_data_criteria.each do |data_criteria|
      data_criteria.modify_patient(patient, @time, @all_value_sets)
    end
  end

  def test_modify_patient_with_characteristic
    characteristic_criteria = @all_data_criteria.find_all { |dc| dc["property"].present? }
  end

  def test_derive_entry

  end

  def test_modify_entry_with_values

  end

  def test_modify_entry_with_negation
    negation_criteria = @all_data_criteria.find_all { |dc| dc["negation_code_list_id"].present? }
  end

  def test_modify_entry_with_fields
    field_criteria = @all_data_criteria.find_all { |dc| dc["negation"] == "" }
  end

  def test_modify_patient_with_entry
    
  end
end