require 'test_helper'

class GeneratorTest < MiniTest::Unit::TestCase
  def setup

  end

  def test_generate_qrda_patients

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

  def classify_entry
    types = [:allProcedures, :proceduresPerformed, :procedureResults, :laboratoryTests, :allMedications, :activeDiagnoses, :inactiveDiagnoses, :resolvedDiagnoses, :allProblems, :allDevices]
    types.each do |type|
      entry_type = HQMF::Generator.classify_entry
      assert_not_nil entry_type.classify.constantize.new
    end
  end
end