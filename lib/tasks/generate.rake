require 'bundler/setup'

require 'hqmf-parser'
require 'hqmf2js'

require_relative '../test-patient-generator'

namespace :generate do
  # @param [String] hqmf An XML file that defines a clinical quality measure.
  # @param [String] value_sets An XLS file that describes code sets which define coded entries on test patients.
  # @param [String] format The standard into which we will save patients. Default is C32.
  # @param [String] out_path The location where we will store a zip of all generated patients. Default is project_root/tmp.
  desc "Generate a zip file of test patients that cover all logical paths through a clinical quality measure."
  task :patients, [:hqmf_path, :value_set_path, :format, :out_path] do |t, args|
    args.with_defaults(:format => "c32", :out_path => ".")
    
    # If no HQMF file or value set file were specified, we shall not pass
    raise "The path to an HQMF file must be specified" unless args[:hqmf_path]
    raise "The path to a Value Set file must be specified" unless args[:value_set_path]
    
    # Pull all of our variables out of args
    hqmf_path = args[:hqmf_path]
    value_set_path = args[:value_set_path]
    format = args[:format]
    out_path = args[:out_path]
    
    # Generate the patients
    patients = TPG::Patient::Generator.patients_from_hqmf(hqmf_path, value_set_path)
    
    # Zip the patients up into the requested format to the out_path

  end
end