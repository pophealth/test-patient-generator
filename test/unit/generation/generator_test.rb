require 'test_helper'

class GeneratorTest < MiniTest::Unit::TestCase
  def setup

  end

  def test_generate_qrda_patients

  end

  def test_create_base_patient
    base_patient = HQMF::Generator.create_base_patient
    expected_fields = [:race, :ethnicity, :languages, :last, :medical_record_number]
    expected_fields.each do |field|
      refute_nil base_patient.send(field)
    end

    initial_attributes = {first: "Custom", last: "Name"}
    base_patient = HQMF::Generator.create_base_patient(initial_attributes)
    assert_equal "Custom", base_patient.first
    assert_equal "Name", base_patient.last
  end

  def test_finalize_patient

  end

  def classify_entry
    types = [:allProcedures, :proceduresPerformed, :procedureResults, :laboratoryTests, :allMedications, :activeDiagnoses, :inactiveDiagnoses, :resolvedDiagnoses, :allProblems, :allDevices]
    types.each do |type|
      entry_type = HQMF::Generator.classify_entry
      assert_not_nil entry_type.classify.constantize.new
    end
  end
end