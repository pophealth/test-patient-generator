module TPG
  class Exporter
    # Export a list of patients to a zip file. Contains nothing but patient records.
    #
    # @param [Array] patients All of the patients that will be exported.
    # @param [String] format The desired format for the patients to be in.
    # @return A zip file containing all given patients in the requested format.
    def self.zip(patients, format, concept_map=nil)
      file = Tempfile.new("patients-#{Time.now.to_i}")
      
      Zip::ZipOutputStream.open(file.path) do |z|
        xslt = Nokogiri::XSLT(File.read("public/cda.xsl"))
        patients.each do |patient|
          next_entry_path = patient_filename(patient)

          if format == "c32"
            z.put_next_entry("#{next_entry_path}.xml")
            z << HealthDataStandards::Export::C32.export(patient)
          elsif format == "ccr"
            z.put_next_entry("#{next_entry_path}.xml")
            z << HealthDataStandards::Export::CCR.export(patient)
          elsif format == "ccda"
            z.put_next_entry("#{next_entry_path}.xml")
            z << HealthDataStandards::Export::CCDA.export(patient)
          elsif format == "html"
            z.put_next_entry("#{next_entry_path}.html")
            z << html_contents(patient, concept_map)
          elsif format == "json"
            z.put_next_entry("#{next_entry_path}.json")
            z << JSON.pretty_generate(JSON.parse(patient.to_json))
          end
        end
      end
      
      file.close
      file
    end
    
    # Export QRDA Category 1 patients to a zip file.
    # Contents are organized with a directory for each measure containing one patient for validation.
    #
    # @param [Hash] measure_patients Measures mapped to the patient that was generated for it.
    # @return A zip file containing all of the QRDA Category 1 patients that were passed in.
    def self.zip_qrda_patients(measure_patients)
      file = Tempfile.new("patients-#{Time.now.to_i}")
      
      Zip::ZipOutputStream.open(file.path) do |zip|
        xslt = Nokogiri::XSLT(File.read("public/cda.xsl"))
        measure_patients.each do |measure, patient|
          # Create a directory for this measure and insert the HTML for this patient.
          zip.put_next_entry(File.join(measure, "#{patient_filename(patient)}.html"))
          zip << html_contents(patient)
        end
      end
      
      file.close
      file
    end

    # Export QRDA Category 1 patients to a zip file.
    # Contents are organized with a directory for each measure containing one patient for validation.
    #
    # @param [Hash] measure_patients Measures mapped to the patient that was generated for it.
    # @return A zip file containing all of the QRDA Category 1 patients that were passed in.
    def self.zip_qrda_cat_1_patients(measure_patients, measure_defs)
      file = Tempfile.new("patients-#{Time.now.to_i}")
      
      Zip::ZipOutputStream.open(file.path) do |zip|
        measure_patients.each do |measure, patient|
          # Create a directory for this measure and insert the HTML for this patient.
          zip.put_next_entry(File.join(measure, "#{patient_filename(patient)}.html"))
          puts "Generating patient for measure #{measure}"
          zip << QrdaGenerator::Export::Cat1.export(patient, [measure_defs[measure]], Time.gm(2011, 1, 1), Time.gm(2011, 12, 31))
        end
      end
      
      file.close
      file
    end
    
    # Generate the HTML output for a Record from Health Data Standards.
    #
    # @param [Record] patient The Record for which we're generating HTML content.
    # @return HTML content to be exported for a Record.
    def self.html_contents(patient, concept_map=nil)
      HealthDataStandards::Export::HTML.export(patient, concept_map)
    end
    
    # Join the first and last name with an underscore and replace any other punctuation that might interfere with file names.
    #
    # @param [Record] patient The patient for whom we're generating a filename.
    # @return A string that can be used safely as a filename.
    def self.patient_filename(patient)
      safe_first_name = patient.first.gsub("'", "")
      safe_last_name = patient.last.gsub("'", "")
      
      "#{safe_first_name}_#{safe_last_name}"
    end
  end
end