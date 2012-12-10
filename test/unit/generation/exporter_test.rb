require 'test_helper'

class ExporterTest < MiniTest::Unit::TestCase
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
    @hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1, codes_by_oid)
    
    # Generate the patients and export them in the requested format to the out_path
    @patients = HQMF::Generator.generate_qrda_patients(
      {@hqmf.id => @hqmf.referenced_data_criteria},
      {@hqmf.id => value_sets})
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
    expected = [File.join("0043", "#{patient.first}_#{patient.last}.html")]
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