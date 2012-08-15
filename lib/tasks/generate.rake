require 'bundler/setup'

require 'hqmf-parser'
require 'hqmf2js'
require 'fileutils'

require_relative '../test-patient-generator'

namespace :generate do
  # @param [String] hqmf An XML file that defines a clinical quality measure.
  # @param [String] value_sets An XLS file that describes code sets which define coded entries on test patients.
  # @param [String] format The standard into which we will save patients. Default is C32.
  # @param [String] out_path The location where we will store a zip of all generated patients. Default is project_root/tmp.
  desc "Generate a zip file of test patients that cover all logical paths through a clinical quality measure."
  task :patients, [:hqmf_path, :value_set_path, :format, :out_path] do |t, args|
    args.with_defaults(:format => "c32", :out_path => "tmp/patients.zip")
    
    # If no HQMF file or value set file were specified, we shall not pass
    raise "The path to an HQMF file must be specified" unless args[:hqmf_path]
    raise "The path to a Value Set file must be specified" unless args[:value_set_path]
    
    # Pull all of our variables out of args
    hqmf_path = args[:hqmf_path]
    value_set_path = args[:value_set_path]
    format = args[:format]
    out_path = args[:out_path]
    
    # Parse all of the value sets
    value_set_parser = HQMF::ValueSet::Parser.new()
    value_set_format ||= HQMF::ValueSet::Parser.get_format(value_set_path)
    value_sets = value_set_parser.parse(value_set_path, {format: value_set_format})

    # Parsed the HQMF file into a model
    codes_by_oid = HQMF2JS::Generator::CodesToJson.from_value_sets(value_sets) if (value_sets) 
    hqmf_contents = Nokogiri::XML(File.new hqmf_path).to_s
    hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1, codes_by_oid)
    
    # Generate the patients
    generator = HQMF::Generator.new(hqmf, value_sets)
    patients = generator.generate_patients()
    
    # Zip the patients up into the requested format to the out_path
    zip = TPG::Exporter.zip(patients, format)
    FileUtils.mv(zip.path, out_path)
  end
  
  # @param [String] measures_dir The directory that contains all the measures for which we're generating patients.
  # @param [String] format The standard into which we will save patients. Default is C32.
  # @param [String] out_path The location where we will store a zip of all generated patients. Default is project_root/tmp.
  desc "Generate a zip file of QRDA Category 1 patients for all measures."
  task :qrda_patients, [:measures_dir, :format, :out_path] do |t, args|
    args.with_defaults(:measures_dir => "./test/fixtures/measure-defs", :format => "html", :out_path => "tmp/patients.zip")
    
    # Pull all of our variables out of args
    measures_dir = args[:measures_dir]
    format = args[:format]
    out_path = args[:out_path]

    # Make a mapping of each measure found in measure_dir to its data criteria and value sets
    measure_needs = {}
    measure_value_sets = {}
    Dir.foreach(measures_dir) do |entry|
      next if entry.starts_with? '.'
      measure_dir = File.join(measures_dir,entry)
      hqmf_path = Dir.glob(File.join(measure_dir,'*.xml')).first
      value_set_path = Dir.glob(File.join(measure_dir,'*.xls')).first
      
      # Parse all of the value sets
      value_set_parser = HQMF::ValueSet::Parser.new()
      value_set_format ||= HQMF::ValueSet::Parser.get_format(value_set_path)
      value_sets = value_set_parser.parse(value_set_path, {format: value_set_format})

      # Parsed the HQMF file into a model
      codes_by_oid = HQMF2JS::Generator::CodesToJson.from_value_sets(value_sets) if (value_sets) 
      hqmf_contents = Nokogiri::XML(File.new hqmf_path).to_s
      hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1, codes_by_oid)
      
      # Add this measure and its value sets to our mapping
      measure_needs[hqmf.id] = hqmf.referenced_data_criteria
      measure_value_sets[hqmf.id] = value_sets
    end
    
    # Generate the patients and export them in the requested format to the out_path
    patients = HQMF::Generator.generate_qrda_patients(measure_needs, measure_value_sets)
    zip = TPG::Exporter.zip_qrda_patients(patients)
    FileUtils.mv(zip.path, out_path)
  end
end