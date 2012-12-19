require 'test_helper'

class ExporterTest < MiniTest::Unit::TestCase
  def setup
    collection_fixtures("data_criteria", "_id")
    collection_fixtures("health_data_standards_svs_value_sets", "_id")
    collection_fixtures("measures")

    measure_path = File.join("test", "fixtures", "measures", "1234.json")
    measure_json = JSON.parse(File.open(measure_path).read, max_nesting: 500)
    @measures = [HQMF::Generator.parse_measure(measure_json)]

    @patients = HQMF::Generator.generate_qrda_patients(HQMF::Generator.determine_measure_needs(@measures))
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
    zip = TPG::Exporter.zip_qrda_html_patients(@patients)

    entries = []
    Zip::ZipFile.open(zip.path) do |zip|
      zip.entries.each do |entry|
        entries << entry.name
        assert entry.size > 0
      end
    end

    patient = @patients.values.first
    filename = TPG::Exporter.patient_filename(patient)
    expected = [File.join("1234", "#{filename}.html")]
    assert_equal entries.size, expected.size
    expected.each {|entry| assert entries.include? entry}
  end

  def test_zip_qrda_cat_1_patients
    zip = TPG::Exporter.zip_qrda_cat_1_patients(@patients, @measures)

    entries = []
    Zip::ZipFile.open(zip.path) do |zip|
      zip.entries.each do |entry|
        entries << entry.name
        assert entry.size > 0
      end
    end
  end

  def test_html_contents
    patient = HQMF::Generator.create_base_patient({first: 'blop', last: 'bloop'})
    patient = HQMF::Generator.finalize_patient(patient)
    html = TPG::Exporter.html_contents(patient)

    assert html.include? "blop"
  end

  def test_patient_filename
    patient = HQMF::Generator.create_base_patient({first: 'blop', last: 'bloop'})
    filename = TPG::Exporter.patient_filename(patient)

    assert_equal filename, "blop_bloop"
  end
end