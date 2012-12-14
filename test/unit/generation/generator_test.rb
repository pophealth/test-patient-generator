require 'test_helper'

class GeneratorTest < MiniTest::Unit::TestCase
  def setup

  end

  def test_generate_qrda_patients
    collection_fixtures("data_criteria", "_id")
    collection_fixtures("health_data_standards_svs_value_sets", "_id")

    all_data_criteria = MONGO_DB["data_criteria"].find({}).map { |dc| HQMF::DataCriteria.from_json(dc["id"], dc) }
    measure_needs = {"123" => all_data_criteria, "456" => all_data_criteria}
    measure_patients = HQMF::Generator.generate_qrda_patients(measure_needs)
    patients = measure_patients.values

    assert_equal patients.size, 2
    refute_nil measure_patients["123"]
    refute_nil measure_patients["456"]

    patients.each do |patient|
      assert_equal patient.encounters.size, 3
      assert_equal patient.medical_equipment.size, 1
      assert_equal patient.medications.size, 1
      assert_equal patient.conditions.size, 1
      assert_equal patient.procedures.size, 1
    end
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

  def test_classify_entry
    types = [:allProcedures, :proceduresPerformed, :procedureResults, :laboratoryTests, :allMedications, :activeDiagnoses, :inactiveDiagnoses, :resolvedDiagnoses, :allProblems, :allDevices]
    types.each do |type|
      entry_type = HQMF::Generator.classify_entry(type)
      refute_nil entry_type.classify.constantize.new
    end
  end
end