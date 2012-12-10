module HQMF
  class Generator
    # Generate patients from lists of DataCriteria. This is originally created for QRDA Category 1 validation testing,
    # i.e. a single patient will be generated per measure with an entry for every data criteria involved in the measure.
    # 
    # @param [Hash] measure_needs A hash of measure IDs mapped to a list of all their data criteria.
    # @param [Hash] measure_value_sets A hash of measure IDs mapped to hashes of value sets used by the DataCriteria in measure_needs.
    # @return [Hash] A hash of measure IDs mapped to a Record that includes all the given data criteria (values and times are arbitrary).
    def self.generate_qrda_patients(measure_needs, measure_value_sets)
      return {} if measure_needs.nil?
      
      measure_patients = {}
      measure_needs.each do |measure, all_data_criteria|
        puts "generating for #{measure}"

        # Prune out all data criteria that create similar entries. Category 1 validation is only checking for ability to access information
        # so to minimize time we only want to include each kind of data once.
        unique_data_criteria = []
        all_data_criteria.each do |data_criteria|
          index = unique_data_criteria.index {|dc| dc.code_list_id == data_criteria.code_list_id && dc.negation_code_list_id == data_criteria.negation_code_list_id && dc.field_values == data_criteria.field_values && dc.status == data_criteria.status}
          unique_data_criteria << data_criteria if index.nil?
        end

        # TODO DELETE THIS - Just makin' some fixtures
        # file = File.open("/Users/agoldstein/Desktop/#{measure}.json", 'w')
        # unique_data_criteria.each do |dc|
        #   file.write(dc.as_json.to_json)
        # end
        # file.close
        
        # Create a patient that includes an entry for every data criteria included in this measure.
        patient = Generator.create_base_patient
        unique_data_criteria.each do |data_criteria|
          # Ignore data criteria that are really just containers.
          next if data_criteria.derivation_operator.present?

          # Generate a random time for this data criteria.
          time = Randomizer.randomize_range(patient.birthdate, nil)

          # Some fields come in with no value or marked as AnyValue (i.e. any value is acceptable, there just must be one). If that's the case, we pick a default here.
          if data_criteria.field_values.present?
            data_criteria.field_values.each do |name, field|
              if field.is_a? HQMF::AnyValue
                if ["ADMISSION_DATETIME", "START_DATETIME", "INCISION_DATETIME"].include? name
                  data_criteria.field_values[name] = time.low
                elsif ["DISCHARGE_DATETIME", "STOP_DATETIME", "REMOVAL_DATETIME"].include? name
                  data_criteria.field_values[name] = time.high
                elsif name.include? "FACILITY"
                  # TODO
                  codes = Coded.select_codes(field.code_list_id, measure_value_sets)
                  field_value = Facility.new("name" => field.title, "codes" => codes)
                elsif name == "REASON"
                  # If we're not explicitly given a code (e.g. HQMF dictates there must be a reason but any is ok), we assign a random one (birth)
                  data_criteria.field_values[name] = Coded.for_code_list("2.16.840.1.113883.3.117.1.7.1.70", "birth")
                elsif name == "ORDINAL"
                  # If we're not explicitly given a code (e.g. HQMF dictates there must be a reason but any is ok), we assign it to be not principle
                  data_criteria.field_values[name] = Coded.for_code_list("2.16.840.1.113883.3.117.1.7.1.265", "birth")
                end
              end
            end
          end
          
          data_criteria.modify_patient(patient, time, measure_value_sets[measure])
        end
        patient.measure_ids ||= []
        patient.measure_ids << measure
        patient.type = "qrda"
        measure_patients[measure] = Generator.finalize_patient(patient)
      end
      
      measure_patients
    end
    
    # Create a patient with trivial demographic information and no coded entries.
    #
    # @return A Record with a blank slate.
    def self.create_base_patient(initial_attributes = nil)
      patient = Record.new
      
      if initial_attributes.nil?
        patient = Randomizer.randomize_demographics(patient)
      else
        initial_attributes.each {|attribute, value| patient.send("#{attribute}=", value)}
      end
      
      patient
    end
        
    # Fill in any missing details that should be filled in on a patient. These include: age, gender, and first name.
    #
    # @param [Record] patient The patient for whom we are about to fill in remaining demographic information.
    # @return A patient with guaranteed complete information necessary for standard formats.
    def self.finalize_patient(patient)
      if patient.birthdate.nil?
        patient.birthdate = Randomizer.randomize_birthdate(patient)
        patient.birthdate = Time.now.to_i
      end
      
      if patient.gender.nil?
        patient.gender = "F"
        patient.first = Randomizer.randomize_first_name(patient.gender)
      end
      
      patient
    end
    
    # Map all patient api coded entry types from HQMF data criteria to Record sections.
    #
    # @param [String] type The type of the coded entry requried by a data criteria.
    # @return The section type for the given patient api function type
    def self.classify_entry(type)
      
      # The possible matches per patientAPI function can be found in hqmf-parser's README
      case type
      when :allProcedures
        "procedures"
      when :proceduresPerformed
        "procedures"
      when :procedureResults
        "procedures"
      when :laboratoryTests
        "vital_signs"
      when :allMedications
        "medications"
      when :activeDiagnoses
        "conditions"
      when :inactiveDiagnoses
        "conditions"
      when :resolvedDiagnoses
        "conditions"
      when :allProblems
        "conditions"
      when :allDevices
        "medical_equipment"
      else
        type.to_s
      end
    end
  end
end