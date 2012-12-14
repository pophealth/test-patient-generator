require 'test_helper'
require 'hqmf2js'

class DataCriteriaTest < MiniTest::Unit::TestCase
  def setup
    # Generate the patients and export them in the requested format to the out_path
    # patients = HQMF::Generator.generate_qrda_patients(
    #   {hqmf.id => hqmf.referenced_data_criteria},
    #   {hqmf.id => value_sets})
    # @patient = patients[hqmf.id]
  end
  
  def test_has_all_expected_entries
    # assert @patient.medications.length > 0
    # assert @patient.procedures.length > 0
    # assert @patient.encounters.length > 0
  end
  
  def test_entry_descriptions_include_appropriate_oid
    # assert @patient.medications[0].description.include?('2.16.840.1.113883.3.464.0001.430')
    # assert @patient.encounters[0].description.include?('2.16.840.1.113883.3.464.0001.49')
    # assert @patient.procedures[0].description.include?('2.16.840.1.113883.3.464.0001.143')
  end
end