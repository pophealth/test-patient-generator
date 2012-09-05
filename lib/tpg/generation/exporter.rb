module TPG
  class Exporter
    # Export a list of patients to a zip file. Contains nothing but patient records.
    #
    # @param [Array] patients All of the patients that will be exported.
    # @param [String] format The desired format for the patients to be in.
    # @return A zip file containing all given patients in the requested format.
    def self.zip(patients, format)
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
          elsif format == "html"
            z.put_next_entry("#{next_entry_path}.html")
            z << html_contents(patient)
          elsif format == "json"
            z.put_next_entry("#{next_entry_path}.json")
            z << JSON.pretty_generate(JSON.parse(patient.to_json))
          end
        end
      end
      
      file.close
      file
    end
    
    # Export QRDA Category 1 patients to a zip file. Contents are organized with a directory for each measure containing one patient for validation.
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
    
    # Export a list of patients to a zip file. Contains the proper formatting of a patient bundle for Cypress,
    # i.e. a bundle JSON file with four subdirectories for c32, ccr, html, and JSON formatting for patients.
    #
    # @param [Array] patients All of the patients that will be exported.
    # @param [String] version The version to mark the bundle.json file of this archive.
    # @return A bundle containing all of the QRDA Category 1 patients that were passed in.
    def self.zip_bundle(patients, name, version)
      file = Tempfile.new("patients-#{Time.now.to_i}")
      
      Zip::ZipOutputStream.open(file.path) do |zip|
        # Generate the bundle file
        zip.put_next_entry("bundle.json")
        zip << {name: name, version: version}.to_json
        
        xslt = Nokogiri::XSLT(File.read("public/cda.xsl"))
        patients.each_with_index do |patient, index|
          filename = "#{index}_#{patient_filename(patient)}"
          
          # Define path names
          c32_path = File.join("patients", "c32", "#{filename}.xml")
          ccr_path = File.join("patients", "ccr", "#{filename}.xml")
          html_path = File.join("patients", "html", "#{filename}.html")
          json_path = File.join("patients", "json", "#{filename}.json")
          
          # For each patient add a C32, CCR, HTML, and JSON file.
          zip.put_next_entry(c32_path)
          zip << HealthDataStandards::Export::C32.export(patient)
          zip.put_next_entry(ccr_path)
          zip << HealthDataStandards::Export::CCR.export(patient)
          zip.put_next_entry(html_path)
          zip << html_contents(patient)
          zip.put_next_entry(json_path)
          zip << JSON.pretty_generate(JSON.parse(patient.to_json))
        end
      end
      
      file.close
      file
    end
    
    # Generate the HTML output for a Record from Health Data Standards.
    #
    # @param [Record] patient The Record for which we're generating HTML content.
    # @return HTML content to be exported for a Record.
    def self.html_contents(patient)
      xslt = Nokogiri::XSLT(File.read("public/cda.xsl"))
      
      # Export the patient as C32 XML so we can build the HTML file.
      doc = Nokogiri::XML::Document.parse(HealthDataStandards::Export::C32.export(patient)) 
      xml = xslt.apply_to(doc)
      html = HealthDataStandards::Export::HTML.export(patient)
      
      # Not sure why this portion is necessary but I copied this section from Cypress
      transformed = Nokogiri::HTML::Document.parse(xml)
      transformed.at_css('ul').after(html)
      
      transformed.to_html
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