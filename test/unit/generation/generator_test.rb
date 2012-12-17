require 'test_helper'

class GeneratorTest < MiniTest::Unit::TestCase
  def setup
    collection_fixtures("data_criteria", "_id")
    collection_fixtures("health_data_standards_svs_value_sets", "_id")
    collection_fixtures("measures")

    @measure_path = File.join("test", "fixtures", "measures", "1234.json")
    @measure_json = JSON.parse(File.open(@measure_path).read, max_nesting: 500)
    @measures = [HQMF::Generator.parse_measure(@measure_json)]
  end

  def test_generate_qrda_patients
    measure_patients = HQMF::Generator.generate_qrda_patients(HQMF::Generator.determine_measure_needs(@measures))
    patients = measure_patients.values
    patient = patients.first

    assert_equal patients.size, 1
    refute_nil measure_patients["1234"]

    assert_equal patient.encounters.size, 1
  end

  def test_create_base_patient
    patient = HQMF::Generator.create_base_patient
    expected_fields = [:race, :ethnicity, :languages, :last, :medical_record_number]
    expected_fields.each do |field|
      refute_nil patient.send(field)
    end

    initial_attributes = {first: "Custom", last: "Name"}
    patient = HQMF::Generator.create_base_patient(initial_attributes)
    assert_equal "Custom", patient.first
    assert_equal "Name", patient.last
  end

  def test_finalize_patient
    patient = HQMF::Generator.create_base_patient
    assert_nil patient.first
    assert_nil patient.birthdate

    HQMF::Generator.finalize_patient(patient)
    refute_nil patient.first
    refute_nil patient.birthdate
  end

  def test_select_unique_data_criteria
    
  end

  def test_create_oid_dictionary

  end

  def test_select_unique_oids

  end

  def test_select_valid_time_range

  end

  def test_apply_field_defaults
    
  end

  def test_determine_measure_needs
    measure_needs = HQMF::Generator.determine_measure_needs(@measures)
    measures = measure_needs.keys
    data_criteria = measure_needs.values

    assert_equal measures.size, 1
    assert_equal data_criteria.first.size, 4

    assert measures.include? "1234"
    refute_nil data_criteria.first.first.code_list_id
  end

  def test_parse_measure
    measure_json = JSON.parse(File.open(@measure_path).read, max_nesting: 500)
    measure = HQMF::Generator.parse_measure(measure_json)

    assert measure.is_a? HQMF::Document
    assert_equal measure.all_data_criteria.size, 4
    assert measure.all_data_criteria.first.field_values.present?
  end

  def test_classify_entry
    types = [:allProcedures, :proceduresPerformed, :procedureResults, :laboratoryTests, :allMedications, :activeDiagnoses, :inactiveDiagnoses, :resolvedDiagnoses, :allProblems, :allDevices]
    types.each do |type|
      entry_type = HQMF::Generator.classify_entry(type)
      refute_nil entry_type.classify.constantize.new
    end
  end
end