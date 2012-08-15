module TPG
  class Exporter
    # Export a list of patients to a zip file.
    #
    # @param [Array] patients All of the patients that will be exported.
    # @param [String] format The desired format for the patients to be in.
    # @return A zip file containing all given patients in the requested format.
    def self.zip(patients, format)
      file = Tempfile.new("patients-#{Time.now.to_i}")
      
      Zip::ZipOutputStream.open(file.path) do |z|
        xslt = Nokogiri::XSLT(File.read("public/cda.xsl"))
        patients.each do |patient|
          safe_first_name = patient.first.gsub("'", '')
          safe_last_name = patient.last.gsub("'", '')
          next_entry_path = "#{safe_first_name}_#{safe_last_name}"

          if format == "c32"
            z.put_next_entry("#{next_entry_path}.xml")
            z << HealthDataStandards::Export::C32.export(patient)
          elsif format == "ccr"
            z.put_next_entry("#{next_entry_path}.xml")
            z << HealthDataStandards::Export::CCR.export(patient)
          elsif format == "html"
            z.put_next_entry("#{next_entry_path}.html")
            
            # Export the patient as C32 XML so we can build the HTML file.
            doc = Nokogiri::XML::Document.parse(HealthDataStandards::Export::C32.export(patient)) 
            xml = xslt.apply_to(doc)
            html = HealthDataStandards::Export::HTML.export(patient)
            
            # Not sure why this portion is necessary but I copied this section from Cypress
            transformed = Nokogiri::HTML::Document.parse(xml)
            transformed.at_css('ul').after(html)
             
            z << transformed.to_html
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
          # Escape punctuation from names that may corrupt the zip file.
          safe_first_name = patient.first.gsub("'", "")
          safe_last_name = patient.last.gsub("'", "")
          
          # Export the patient as C32 XML so we can build the HTML file.
          doc = Nokogiri::XML::Document.parse(HealthDataStandards::Export::C32.export(patient)) 
          xml = xslt.apply_to(doc)
          html = HealthDataStandards::Export::HTML.export(patient)
          
          # Not sure why this portion is necessary but I copied this section from Cypress
          transformed = Nokogiri::HTML::Document.parse(xml)
          transformed.at_css('ul').after(html)
          
          # Create a directory for this measure and insert the HTML for this patient.
          zip.put_next_entry(File.join(measure, "#{safe_first_name}_#{safe_last_name}.html"))
          zip << transformed.to_html
        end
      end
      
      file.close
      file
    end
  end
end