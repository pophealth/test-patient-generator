module HQMF
  class DataCriteria
    # Modify a Record with this data criteria. Acceptable times and values are defined prior to this function.
    #
    # @param [Record] patient The Record that is being modified. 
    # @param [Range] time An acceptable range of times for the coded entry being put on this patient.
    # @param [Hash] value_sets The value sets that this data criteria references.
    # @return The modified patient. The passed in patient object will be modified by reference already so this is just for potential convenience.
    def modify_patient(patient, time, value_sets)
      # Figure out what kind of data criteria we're looking at
      if type == :characteristic and property != nil and patient_api_function == nil
        # We have a special case on our hands.
        if property == :birthtime
          patient.birthdate = time.low.to_seconds
        elsif value.present? && value.system == "Gender"
          patient.gender = value.code
          patient.first = Randomizer.randomize_first_name(value.code)
        elsif property == :clinicalTrialParticipant
          patient.clinicalTrialParticipant = true
        end
      else
        # Otherwise this is a regular coded entry. Start by choosing the correct type and assigning basic metadata.
        entry_type = Generator.classify_entry(patient_api_function)
        entry = entry_type.classify.constantize.new
        entry.description = "#{description} (Code List: #{code_list_id})"
        entry.start_time = time.low.to_seconds if time.low
        entry.end_time = time.high.to_seconds if time.high
        entry.status = status
        entry.codes = Coded.select_codes(code_list_id, value_sets)
        entry.oid = HQMF::DataCriteria.template_id_for_definition(definition, status, negation)

        # If the value itself has a code, it will be a Coded type. Otherwise, it's just a regular value with a unit.
        if value.present? && !value.is_a?(AnyValue)
          entry.values ||= []
          if value.type == "CD"
            entry.values << CodedResultValue.new({codes: Coded.select_codes(value.code_list_id, value_sets)})
          else
            entry.values << PhysicalQuantityResultValue.new(value.format)
          end
        end

        # Choose a code from each relevant code vocabulary for this entry's negation, if it is negated and referenced.
        if negation && negation_code_list_id.present?
          entry.negation_ind = true
          entry.negation_reason = Coded.select_code(negation_code_list_id, value_sets)
        end

        # Additional fields (e.g. ordinality, severity, etc) seem to all be special cases. Capture them here.
        if field_values.present?
          field_values.each do |name, field|
            next if field.nil?

            if field.type == "CD"
              field_value = Coded.select_codes(field.code_list_id, value_sets)
            else
              field_value = field.format
            end

            # We have a few special cases. The most common problem is that the field doesn't fit neatly into a C32 so we default to preexisting fields. Other special cases are explained inline below.
            if ["ADMISSION_DATETIME", "START_DATETIME", "INCISION_DATETIME"].include? name
              field_value = time.low
            elsif ["DISCHARGE_DATETIME", "STOP_DATETIME", "REMOVAL_DATETIME"].include? name
              field_value = time.high
            elsif name == "REASON"
              # If we're not explicitly given a code (e.g. HQMF dictates there must be a reason but any is ok), we assign a random one (it's chickenpox pneumonia.)
              field_value ||= {"SNOMED-CT" => ["195911009"]}
            elsif name == "FACILITY_LOCATION"
              field_value = Facility.new("name" => field.title, "codes" => field_value)
            end

            begin
              field_accessor = HQMF::DataCriteria::FIELDS[name][:coded_entry_method]
              entry.send("#{field_accessor}=", value)
            rescue
              puts "Unknown field #{name} was unable to be added to the patient"
            end
          end
        end
         
        # Figure out which section this entry will be added to. Some entry names don't map prettily to section names.
        section_map = { "lab_results" => "results" }
        section_name = section_map[entry_type]
        section_name ||= entry_type

        # Add the updated section to this patient.
        section = patient.send(section_name)
        section.push(entry)
        
        patient
      end
    end
  end
end