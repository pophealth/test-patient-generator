module HQMF
  # This is the only place where we actually know how t alter a patient record
  class DataCriteria
    attr_accessor :generation_range
    
    def generate(base_patients)
      
    end
    
    def generate_pass(base_patients)
      
    end
    
    def generate_fail(base_patients)
      
    end
    
    # TODO When referring to elements, we need to check to see if they exist already
    # 
    # Order of operations - temporal references, subset operators, derivation operators
    def generate_match(base_patients)
      # Calculate temporal information
      acceptable_times = []
      
      # Evaluate all of the temporal restrictions on this data criteria. Times are anded (intersected) together.
      unless temporal_references.nil?
        temporal_references.each do |reference|
          # This is an array
          # acceptable_times = reference.generate_match(base_patients)
          acceptable_times.concat(reference.generate_match(base_patients))
        end
      end
      
      # Apply any subset operators (e.g. FIRST)
      # e.g., if the subset operator is THIRD we need to make at least three entries
      unless subset_operators.nil?
        subset_operators.each do |subset_operator|
          subset_operator.generate_match(base_patients)
        end
      end
      
      # Apply any derivation operator (e.g. UNION)
      unless derivation_operator.nil?
        Range.merge(DerivationOperator.generate_match(base_patients, children_criteria, derivation_operator), acceptable_times)
      end
      
      # Set the acceptable ranges for this data criteria so any parents can read it
      @generation_range = acceptable_times

      # Calculate value information
      potential_values = []

      # Figure out what kind of data criteria we're looking at
      if type == :characteristic && property == :birthtime
        # Special case for handling age
        acceptable_times.each do |acceptable_time|
          # Modify the patients for this data_criteria
          base_patients.each do |patient|
            patient.send("birthdate=", acceptable_time.low.to_seconds)
          end
        end
      elsif type == :characteristic && !value.nil? && value.system == "Gender"
        base_patients.each do |patient|
          patient.gender = value.code
          patient.first = Randomizer.randomize_first_name(value.code)
        end
      elsif type != :derived
        value_sets = Generator::value_sets[Generator::value_sets.index{|value_set| value_set["oid"] == code_list_id}]
        
        acceptable_times.each do |acceptable_time|
          entry_type = Generator.classify_entry(patient_api_function)
          entry = entry_type.classify.constantize.new
          entry.description = description
          entry.start_time = acceptable_time.low.to_seconds
          entry.end_time = acceptable_time.high.to_seconds
          entry.status = status
          
          code_sets = {}
          value_sets["code_sets"].each do |value_set|
            code_sets[value_set["code_set"]] = value_set["codes"]
          end
          entry.codes = code_sets
          
          base_patients.each do |patient|
            section = patient.send(entry_type)
            section.push(entry)
          end
        end
      end
      
      base_patients
    end
    
    private
    
    def generate_permutations(base_patients)
      
    end
  end
end