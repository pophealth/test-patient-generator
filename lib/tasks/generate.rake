require 'bundler/setup'

require 'hqmf-parser'
require 'hqmf2js'

require 'fileutils'
require_relative '../test-patient-generator'

Mongoid.configure do |config|
  config.sessions = {
    default: {
      hosts: ["localhost: 27017"],
      database: "cypress_development"
    }
  }
end
MONGO_DB = Mongoid.default_session

namespace :generate do
  # @param [String] measures_dir The directory that contains all the JSON measures for which we're generating patients.
  # @param [String] format The type of zip that will be generated. Possible values are "bundle" for a Cypress test deck bundle or "qrda" for patients organized by measure.
  # @param [String] out_path The location where we will store a zip of all generated patients. Default is project_root/tmp.
  desc "Generate a zip file of QRDA Category 1 patients for all measures."
  task :qrda_patients, [:measures_dir, :format, :out_path] do |t, args|
    args.with_defaults(:measures_dir => "./test/fixtures/measure-defs", :format => "qrda", :out_path => "./tmp")
    
    # Pull all of our variables out of args
    measures_dir = args[:measures_dir]
    format = args[:format]
    out_path = args[:out_path]

    # Make a mapping of each measure found in measure_dir to its data criteria
    measure_needs = {}
    Dir.foreach(measures_dir) do |entry|
      next if entry.starts_with? '.'
      
      # Read and parse the measure file
      measure_path = File.join(measures_dir, entry)
      measure = JSON.parse(File.open(measure_path).read, max_nesting: 500)

      # Extract the data criteria and add it as the requirements for this measure
      data_criteria = measure["data_criteria"].map{|data_criteria| data_criteria.values.first}
      measure_needs[measure["nqf_id"]] = data_criteria
    end
    
    # Generate the patients and export them in the requested format to the out_path
    patients = HQMF::Generator.generate_qrda_patients(measure_needs)
    zip = TPG::Exporter.send("zip_#{format}_patients", patients, measure_needs)
    
    # Create the outpath if it doesn't already exist and then write out the generated zip file.
    out_file = File.join(out_path, "patients.zip")
    FileUtils.mkdir_p out_path
    FileUtils.mv(zip.path, out_file)
    puts "Generated #{measure_needs.size} #{format} patients. Saved to #{out_file}"
  end
end