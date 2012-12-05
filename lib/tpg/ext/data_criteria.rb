module HQMF
  class DataCriteria
    attr_accessor :generation_range, :values
    
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
        binding.pry if patient_api_function.nil?
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
        
        if values.present?
           entry.values ||= []
           values.each do |value|
             if value.type == "CD"
               entry.values << CodedResultValue.new({codes: Coded.select_codes(value.code_list_id, value_sets), description: Coded.select_value_sets(value.code_list_id, value_sets)['description']})
             else
               entry.values << PhysicalQuantityResultValue.new(value.format)
             end
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
            
            # These fields are sometimes Coded and sometimes Values.
            if field.type == "CD"
              codes = Coded.select_codes(field.code_list_id, value_sets)
            elsif field.type == "IVL_PQ" || field.type =='PQ'
              value = field.format
            end
            
            case name
            when "ORDINAL"
              entry.ordinality_code = codes
            when "FACILITY_LOCATION"
              entry.facility = Facility.new("name" => field.title, "codes" => codes)
            when "CUMULATIVE_MEDICATION_DURATION"
              entry.cumulative_medication_duration = value              
            when "SEVERITY"
              entry.severity = codes
            when "REASON"
              # If we're not explicitly given a code (e.g. HQMF dictates there must be a reason but any is ok), we assign a random one (it's chickenpox pneumonia.)
              entry.reason = codes || {"SNOMED-CT" => ["195911009"]}
            when "SOURCE"
              entry.source = codes
            when "DISCHARGE_STATUS"
              entry.discharge_disposition = codes
            when "DISCHARGE_DATETIME"
              entry.discharge_time = time.high
            when "ADMISSION_DATETIME"
              entry.admit_time = time.low
            when "LENGTH_OF_STAY"
              # This is resolved in the patient API with discharge and admission datetimes.
            when "ROUTE"
              entry.route = codes
            when "START_DATETIME"
              entry.start_time = time.low
            when "STOP_DATETIME"
              entry.end_time = time.high
            when "ANATOMICAL_STRUCTURE"
              entry.anatomical_structure = codes
            when "REMOVAL_DATETIME"
              entry.end_time = time.high
            when "INCISION_DATETIME"
              entry.incision_date_time = time.low
            when "TRANSFER_TO"
              entry.transfer_to = codes
            when "TRANSFER_FROM"
              entry.transfer_from = codes
            else
              
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