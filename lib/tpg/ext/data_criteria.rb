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
    
    def generate_match(base_patients)
      # Calculate temporal information
      potential_times = []
      
      unless temporal_references.nil?
        temporal_references.each do |reference|
          potential_times.concat(reference.generate_match(base_patients))
        end
      end
      # Set the acceptable ranges for this data criteria so any parents can read it
      @generation_range = potential_times

      # Calculate value information
      potential_values = []

      # Derive what kind of coded entry we're looking at
      if type == :characteristic && property == :birthtime
        # We've got a special case on our hands
        potential_times.each do |potential_time|
          # Modify the patients for this data_criteria
          base_patients.each do |patient|
            patient.send("birthdate=", potential_time.low.to_seconds)
          end
        end
      elsif type == :characteristic && !value.nil? && value.system == "Gender"
        base_patients.each do |patient|
          patient.gender = value.code
          patient.first = Randomizer.randomize_first_name(value.code)
        end
      else
        value_sets = Generator::value_sets[Generator::value_sets.index{|value_set| value_set["oid"] == code_list_id}]
        
        potential_times.each do |potential_time|
          entry_type = Generator.classify_entry(patient_api_function)
          entry = entry_type.classify.constantize.new
          entry.description = description
          entry.start_time = potential_time.low.to_seconds
          entry.end_time = potential_time.high.to_seconds
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