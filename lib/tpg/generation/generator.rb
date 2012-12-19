module HQMF
  class Generator
    # Generate patients from lists of DataCriteria. This is originally created for QRDA Category 1 validation testing,
    # i.e. a single patient will be generated per measure with an entry for every data criteria involved in the measure.
    # 
    # @param [Hash] measure_needs A hash of measure IDs mapped to a list of all their data criteria in JSON.
    # @return [Hash] A hash of measure IDs mapped to a Record that includes all the given data criteria (values and times are arbitrary).
    def self.generate_qrda_patients(measure_needs)      
      return {} if measure_needs.nil?
      
      measure_patients = {}
      measure_needs.each do |measure, all_data_criteria|
        # Define a list of unique data criteria and matching value sets to create a patient for this measure.
        unique_data_criteria = select_unique_data_criteria(all_data_criteria)
        oids = select_unique_oids(all_data_criteria)
        value_sets = create_oid_dictionary(oids)
        
        # Create a patient that includes an entry for every data criteria included in this measure.
        patient = Generator.create_base_patient
        unique_data_criteria.each do |data_criteria|
          # Ignore data criteria that are really just containers.
          next if data_criteria.derivation_operator.present?

          # Prepare and apply our parameters for modifying the patient based on the data criteria.
          time = select_valid_time_range(patient, data_criteria)
          apply_field_defaults(data_criteria, time)
          data_criteria.modify_patient(patient, time, value_sets)
        end

        # Add final data for the patient, e.g. that they were designed for the measure, possibly a birthdate, etc.
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
        patient.first ||= Randomizer.randomize_first_name(patient.gender)
      end
      
      patient
    end

    # Select all unique data criteria from a list. Category 1 validation is only checking for ability to access information
    # so to minimize time we only want to include each kind of data once.
    #
    # @param [Array] all_data_criteria A list of HQMF::DataCriteria to be sifted through.
    # @return The unique list of data criteria extracted from all_data_criteria
    def self.select_unique_data_criteria(all_data_criteria)
      all_data_criteria.flatten!
      all_data_criteria.uniq!
      
      unique_data_criteria = []
      all_data_criteria.each do |data_criteria|
        index = unique_data_criteria.index {|dc| dc.code_list_id == data_criteria.code_list_id && dc.negation_code_list_id == data_criteria.negation_code_list_id && dc.field_values == data_criteria.field_values && dc.status == data_criteria.status}
        unique_data_criteria << data_criteria if index.nil?
      end

      unique_data_criteria
    end

    # 
    #
    # @param [Array] oids 
    # @return 
    def self.create_oid_dictionary(oids)
      value_sets = []
      HealthDataStandards::SVS::ValueSet.any_in(oid: oids).each do |value_set|
        code_sets = value_set.concepts.map { |concept| {"code_set" => concept.code_system_name, "codes" => [concept.code]} }
        value_sets << {"code_sets" => code_sets, "oid" => value_set.oid, "concept" => value_set.display_name}
      end

      value_sets
    end

    #
    #
    # @param [Array] all_data_criteria
    # @return
    def self.select_unique_oids(all_data_criteria)
      oids = []
      all_data_criteria.each do |dc|
        oids << dc.code_list_id if dc.code_list_id.present?
        oids << dc.negation_code_list_id if dc.negation_code_list_id.present?
        oids << dc.value.code_list_id if dc.value.present? && dc.value.type == "CD"

        dc.field_values.each {|name, field| oids << field.code_list_id if field.present? && field.type == "CD"} if dc.field_values.present?
      end

      oids << "2.16.840.1.113883.3.117.1.7.1.70"
      oids << "2.16.840.1.113883.3.117.2.7.1.14"

      oids.flatten!
      oids.uniq!
      oids.compact
    end

    # Create a random time range for an entry to occur. It is guaranteed to be within the lifespan of the patient and will last no longer than a day.
    #
    # @param [Record] patient The patient for whom this range is being generated.
    # @param [HQMF::DataCriteria] data_criteria The data criteria for which we're creating an entry.
    # @return A time range that can be used to create an entry for this data criteria.
    def self.select_valid_time_range(patient, data_criteria)
      earliest_time = patient.birthdate
      latest_time = patient.deathdate

      # Make sure all ranges occur within the bounds of birth and death. If this data criteria is deciding one of those two, place this range outside of our 35 year range for entries.
      if data_criteria.property.present?
        if data_criteria.property == :birthtime
          earliest_time = HQMF::Randomizer.randomize_birthdate(patient)
          latest_time = earliest_time.advance(days: 1)
        elsif data_criteria.property == :expired
          earliest_time = Time.now
          latest_time = earliest_time.advance(days: 1)
        end
      end

      time = Randomizer.randomize_range(earliest_time, latest_time, {days: 1})
    end

    #
    #
    # @param [HQMF::DataCriteria] date_criteria
    # @return
    def self.apply_field_defaults(data_criteria, time)
      return nil if data_criteria.field_values.nil?

      # Some fields come in with no value or marked as AnyValue (i.e. any value is acceptable, there just must be one). If that's the case, we pick a default here.
      data_criteria.field_values.each do |name, field|
        if field.is_a? HQMF::AnyValue
          if ["ADMISSION_DATETIME", "START_DATETIME", "INCISION_DATETIME"].include? name
            data_criteria.field_values[name] = time.low
          elsif ["DISCHARGE_DATETIME", "STOP_DATETIME", "REMOVAL_DATETIME"].include? name
            data_criteria.field_values[name] = time.high
          elsif name == "REASON"
            # If we're not explicitly given a code (e.g. HQMF dictates there must be a reason but any is ok), we assign a random one (birth)
            data_criteria.field_values[name] = Coded.for_code_list("2.16.840.1.113883.3.117.1.7.1.70", "birth")
          elsif name == "ORDINAL"
            # If we're not explicitly given a code (e.g. HQMF dictates there must be a reason but any is ok), we assign it to be not principle
            data_criteria.field_values[name] = Coded.for_code_list("2.16.840.1.113883.3.117.2.7.1.14", "principle")
          end
        end
      end
    end

    # Takes an Array of meassures and builds a Hash keyed by NQF ID with the values being an Array of data criteria.
    #
    # @param [Array] measures A list of HQMF::Documents for which patients will be generated.
    # @return A hash of measure IDs for which we're generating patients, mapped to an array of HQMF::DataCriteria.
    def self.determine_measure_needs(measures)
      measure_needs = {}
      measures.each do |measure|
        measure_needs[measure.id] = measure.all_data_criteria
      end

      measure_needs
    end

    # Parses a JSON representation of a measure from a Bonnie Bundle into an hqmf-parser ready format.
    #
    # @param [Hash] measure JSON representation of a measure
    # @return Tweaked JSON that has fields in the places hqmf-parser expects
    def self.parse_measure(measure_json)
      # HQMF Parser expects just a hash of ID => data_criteria, so translate to that format here.
      translated_data_criteria = {}
      measure_json["data_criteria"].each { |data_criteria| translated_data_criteria[data_criteria.keys.first] = data_criteria.values.first }
      measure_json["data_criteria"] = translated_data_criteria
      
      # HQMF::Documents have fields for hqmf_id and id, but not NQF ID. We'll store NQF_ID in ID.
      measure_json["id"] = measure_json["nqf_id"]
      measure_json["source_data_criteria"] = []

      measure = HQMF::Document.from_json(measure_json)
      measure.all_data_criteria.each do |data_criteria|
        data_criteria.values ||= []
        data_criteria.values << data_criteria.value if data_criteria.value && data_criteria.value.type != "ANYNonNull"
      end

      measure
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