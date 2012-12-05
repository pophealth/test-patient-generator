require 'bundler/setup'

require 'hqmf-parser'
require 'hqmf2js'
require 'fileutils'
require 'digest/sha1'

require_relative '../test-patient-generator'

Mongoid.configure do |config|
  config.sessions = { default: { hosts: [ "localhost:27017" ], database: 'cypress_development' }}
end

namespace :generate do
  # @param [String] measures_dir The directory that contains all the measures for which we're generating patients.
  # @param [String] name The name of the test deck that will be generated.
  # @param [String] version The version of the test deck that will be generated.
  # @param [String] out_path The location where we will store a zip of all generated patients. Default is project_root/tmp.
  desc "Generate a zip file of test patients that cover all logical paths through a set of clinical quality measures."
  task :patients, [:measures_dir, :name, :version, :out_path] do |t, args|
    args.with_defaults(:measures_dir => "./test/fixtures/measure-defs", :name => "Meaningful Use Stage 1 Test Deck", :version => "1.0.x", :out_path => "./tmp")
    
    # Pull all of our variables out of args
    measures_dir = args[:measures_dir]
    name = args[:name]
    version = args[:version]
    out_path = args[:out_path]
    
    patients = []
    Dir.foreach(measures_dir) do |entry|
      next if entry.starts_with? '.'
      measure_dir = File.join(measures_dir,entry)
      hqmf_path = Dir.glob(File.join(measure_dir,'*.xml')).first
      
      # Parse all of the value sets
      value_set_parser = HQMF::ValueSet::Parser.new()
      value_set_format ||= HQMF::ValueSet::Parser.get_format(value_set_path)
      value_sets = value_set_parser.parse(value_set_path, {format: value_set_format})

      # Parsed the HQMF file into a model
      codes_by_oid = HQMF2JS::Generator::CodesToJson.from_value_sets(value_sets) if (value_sets) 
      hqmf_contents = Nokogiri::XML(File.new hqmf_path).to_s
      hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1, codes_by_oid)
      
      # Add this measure and its value sets to our mapping
      generator = HQMF::Generator.new(hqmf, value_sets)
      patients.concat! generator.generate_patients()
    end
    
    # Zip the patients up into the requested format to the out_path
    zip = TPG::Exporter.zip_bundle(patients, name, version)
    FileUtils.mkdir_p out_path
    FileUtils.mv(zip.path, File.join(out_path, "patients.zip"))
  end
  
  # @param [String] measures_dir The directory that contains all the measures for which we're generating patients.
  # @param [String] format The type of zip that will be generated. Possible values are "bundle" for a Cypress test deck bundle or "qrda" for patients organized by measure.
  # @param [String] name The name of the test deck that will be generated.
  # @param [String] version The version of the test deck that will be generated.
  # @param [String] out_path The location where we will store a zip of all generated patients. Default is project_root/tmp.
  desc "Generate a zip file of QRDA Category 1 patients for all measures."
  task :qrda_patients, [:measures_dir, :format, :name, :version, :out_path] do |t, args|
    args.with_defaults(:measures_dir => "./test/fixtures/measure-defs", :format => "bundle", :name => "Meaningful Use Stage 1 Test Deck", :version => "1.0.x", :out_path => "./tmp")
    
    # Pull all of our variables out of args
    measures_dir = args[:measures_dir]
    format = args[:format]
    name = args[:name]
    version = args[:version]
    out_path = args[:out_path]

    # Make a mapping of each measure found in measure_dir to its data criteria and value sets
    measure_needs = {}
    measure_value_sets = {}
    measure_defs = {}
    Dir.mkdir('cache') unless Dir.exists?('cache')
    Dir.foreach(measures_dir) do |entry|
      next if entry.starts_with? '.'
      entry_name_digest = Digest::SHA1.hexdigest(entry)
      hqmf = nil
      value_sets = nil
      if File.exists?("cache/#{entry_name_digest}")
        hqmf = Marshal.load(File.new("cache/#{entry_name_digest}", 'r'))
        value_sets = Marshal.load(File.new("cache/#{entry_name_digest}_value_sets", 'r'))
        puts "Read from file #{hqmf.id}"
      else
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
        puts "Parsed #{hqmf.id}"
        File.open("cache/#{entry_name_digest}", 'w+') do |f|
          Marshal.dump(hqmf, f)
        end
        File.open("cache/#{entry_name_digest}_value_sets", 'w+') do |f|
          Marshal.dump(value_sets, f)
        end
      end
      
      # Add this measure and its value sets to our mapping
      
      measure_needs[hqmf.id] = hqmf.referenced_data_criteria
      measure_value_sets[hqmf.id] = value_sets
      measure_defs[hqmf.id] = hqmf
    end
    
    # Generate the patients and export them in the requested format to the out_path
    patients = HQMF::Generator.generate_qrda_patients(measure_needs, measure_value_sets)
    case format 
    when "bundle"
      zip = TPG::Exporter.zip_bundle(patients.values, name, version)
    when "qrda"
      zip = TPG::Exporter.zip_qrda_patients(patients)
    when "qrda_cat_1"
      zip = TPG::Exporter.zip_qrda_cat_1_patients(patients, measure_defs)
    end
    
    # Create the outpath if it doesn't already exist and then write out the generated zip file.
    FileUtils.mkdir_p out_path
    FileUtils.mv(zip.path, File.join(out_path, "patients.zip"))
  end
end