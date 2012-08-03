module HQMF
  class DataCriteria
    attr_accessor :generation_range

    # Order of operations - temporal references, subset operators, derivation operators
    # 
    # @param [Array] base_patients
    def generate(base_patients)
      acceptable_times = []
      
      # Evaluate all of the temporal restrictions on this data criteria.
      unless temporal_references.nil?
        # Generate for patients based on each reference and merge the potential times together.
        temporal_references.each do |reference|
          acceptable_time = reference.generate(base_patients)
          acceptable_times = DerivationOperator.intersection(acceptable_time, acceptable_times)
        end
      end
      
      binding.pry
      
      # Apply any subset operators (e.g. FIRST)
      # e.g., if the subset operator is THIRD we need to make at least three entries
      unless subset_operators.nil?
        subset_operators.each do |subset_operator|
          subset_operator.generate(base_patients)
        end
      end
      
      # Apply any derivation operator (e.g. UNION)
      unless derivation_operator.nil?
        Range.merge(DerivationOperator.generate(base_patients, children_criteria, derivation_operator), acceptable_times)
      end
      
      # Set the acceptable ranges for this data criteria so any parents can read it
      @generation_range = acceptable_times

      # Calculate value information
      acceptable_values = []
      acceptable_values << value
      
      # Walk through all acceptable time/value combinations and alter out patients
      base_patients.each do |patient|
        acceptable_times.each do |time|
          acceptable_values.each do |value|
            modify_patient(patient, time, value)
          end
        end
      end
    end
    
    #
    #
    # @param [Array] acceptable_times
    # @param [Array] acceptable_values
    def permutate(acceptable_times, acceptable_values)
      
    end
    
    #
    #
    # @param [Record] patient
    # @param [Range] time
    # @param [Range] value
    # @param [Hash] value_sets
    def modify_patient(patient, time, value, value_sets = nil)
      # Figure out what kind of data criteria we're looking at
      if type == :characteristic && property == :birthtime
        patient.birthdate = acceptable_time.low.to_seconds
      elsif type == :characteristic && !value.nil? && value.system == "Gender"
        patient.gender = value.code
        patient.first = Randomizer.randomize_first_name(value.code)
      elsif type != :derived
        value_sets ||= Generator::value_sets[Generator::value_sets.index{|value_set| value_set["oid"] == code_list_id}]
        
        entry_type = Generator.classify_entry(patient_api_function)
        entry = entry_type.classify.constantize.new
        entry.description = description
        entry.start_time = time.low.to_seconds
        entry.end_time = time.high.to_seconds
        entry.status = status
        entry.value = { "scalar" => value.low.value, "unit" => value.low.unit }
          
        code_sets = {}
        value_sets["code_sets"].each do |value_set|
          code_sets[value_set["code_set"]] = value_set["codes"]
        end
        entry.codes = code_sets
          
        section = patient.send(entry_type)
        section.push(entry)
      end
    end
  end
end