require 'test_helper'

class ExporterTest < MiniTest::Unit::TestCase
  def setup
    collection_fixtures("data_criteria", "_id")
    collection_fixtures("health_data_standards_svs_value_sets", "_id")

    all_data_criteria = MONGO_DB["data_criteria"].find({}).to_a
    measure_needs = {"123" => all_data_criteria}
    @patients = HQMF::Generator.generate_qrda_patients(measure_needs)
  end

  def test_zip
    supported_formats = {"c32" => "xml", "ccr" => "xml", "ccda" => "xml", "json" => "json", "html" => "html"}
    supported_formats.each do |format, extension|
      patients = @patients.values
      zip = TPG::Exporter.zip(patients, format)

      entries = []
      Zip::ZipFile.open(zip.path) do |zip|
        zip.entries.each do |entry|
          entries << entry.name
          assert entry.size > 0
        end
      end

      patient = patients.first
      patient_name = "#{patient.first}_#{patient.last}"
      assert_equal entries.size, 1
      assert_equal entries.first, "#{patient_name}.#{extension}"
    end
  end

  def test_zip_qrda_patients
    zip = TPG::Exporter.zip_qrda_patients(@patients)

    entries = []
    Zip::ZipFile.open(zip.path) do |zip|
      zip.entries.each do |entry|
        entries << entry.name
        assert entry.size > 0
      end
    end

    patient = @patients.values.first
    expected = [File.join("123", "#{patient.first}_#{patient.last}.html")]
    assert_equal entries.size, expected.size
    expected.each {|entry| assert entries.include? entry}
  end

  def test_zip_qrda_cat_1_patients
    skip "QRDA Cat 1 generation still requires value sets to be cached in the db."
    # measure_defs = {@hqmf.id => @hqmf}
    # zip = TPG::Exporter.zip_qrda_cat_1_patients(@patients, measure_defs)

    # entries = []
    # Zip::ZipFile.open(zip.path) do |zip|
    #   zip.entries.each do |entry|
    #     entries << entry.name
    #     assert entry.size > 0
    #   end
    # end

    # patient = @patients.values.first
    # binding.pry
    # expected = [File.join("0043", "#{patient.first}_#{patient.last}.html")]
    # assert_equal entries.size, expected.size
    # expected.each {|entry| assert entries.include? entry}
  end
end