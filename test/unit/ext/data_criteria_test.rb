require 'test_helper'

class DataCriteriaTest < MiniTest::Unit::TestCase

  def setup
    measure_dir = File.join('test', 'fixtures', 'measure-defs', '0043')
    hqmf_path = File.join(measure_dir, '0043.xml')
    value_set_path = File.join(measure_dir,'0043.xls')
    
    # Parse all of the value sets
    value_set_parser = HQMF::ValueSet::Parser.new()
    value_set_format = HQMF::ValueSet::Parser.get_format(value_set_path)
    value_sets = value_set_parser.parse(value_set_path, {format: value_set_format})

    # Parsed the HQMF file into a model
    codes_by_oid = HQMF2JS::Generator::CodesToJson.from_value_sets(value_sets)
    hqmf_contents = File.read(hqmf_path)
    hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1, codes_by_oid)
    
    # Generate the patients and export them in the requested format to the out_path
    patients = HQMF::Generator.generate_qrda_patients(
      {hqmf.id => hqmf.referenced_data_criteria},
      {hqmf.id => value_sets})
    @patient = patients[hqmf.id]
  end
  
  def test_has_all_expected_entries
    assert @patient.medications.length > 0
    assert @patient.procedures.length > 0
    assert @patient.encounters.length > 0
  end
  
  def test_entry_descriptions_include_appropriate_oid
    assert @patient.medications[0].description.include?('2.16.840.1.113883.3.464.0001.430')
    assert @patient.encounters[0].description.include?('2.16.840.1.113883.3.464.0001.49')
    assert @patient.procedures[0].description.include?('2.16.840.1.113883.3.464.0001.143')
  end

end