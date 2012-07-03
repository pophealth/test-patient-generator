module TPG
  class Exporter
    def self.zip(patients, format)
      file = Tempfile.new("patients-#{Time.now.to_i}")
      
      Zip::ZipOutputStream.open(file.path) do |z|
        xslt = Nokogiri::XSLT(File.read("public/cda.xsl"))
        patients.each_with_index do |patient, i|
          safe_first_name = patient.first.gsub("'", '')
          safe_last_name = patient.last.gsub("'", '')
          next_entry_path = "#{i}_#{safe_first_name}_#{safe_last_name}"

          z.put_next_entry("#{next_entry_path}.xml")
          if format == "c32"
            z << HealthDataStandards::Export::C32.export(patient)
          elsif format == "ccr"
            z << HealthDataStandards::Export::CCR.export(patient)
          end
        end
      end
      
      file.close
      file
    end
  end
end