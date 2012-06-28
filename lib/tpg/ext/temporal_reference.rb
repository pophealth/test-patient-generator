module HQMF
  # Generates a Range to define the timing of a data_criteria
  class TemporalReference
    def generate(base_patients)
      
    end
    
    def generate_pass(base_patients)
      
    end
    
    def generate_fail(base_patients)
      
    end
    
    def generate_match(base_patients)
      acceptable_times = []
      
      if reference.id == "MeasurePeriod"
        relative_time = Generator::hqmf.measure_period
      else
        data_criteria = Generator::hqmf.data_criteria(reference.id)
        relative_time = data_criteria.generate_match(base_patients)
      end

      case type
      when "DURING"
        matching_times = relative_time.generate_permutations(1, 1)
      when "SBS" # Starts before start
        matching_times = relative_time.generate_permutations(-1, 1)
      when "SAS" # Starts after start
        
      when "SBE" # Starts before end
        
      when "SAE" # Starts after end
        
      when "EBS" # Ends before start
        
      when "EAS" # Ends after start
        
      when "EBE" # Ends before end
        
      when "EAE" # Ends after end
        
      when "SDU" # Starts during
        
      when "EDU" # Ends during
        
      when "ECW" # Ends concurrent with
        
      when "SCW" # Starts concurrent with
        
      when "CONCURRENT"
        
      end
      
      matching_times.each do |matching_time|
        if range
          acceptable_times << Range.merge_ranges(range, matching_time)
        else
          acceptable_times << matching_time
        end
      end

      # Note we return the possible times to the calling data criteria, not patients
      return acceptable_times
    end
    
    private
    
    def generate_permutations(base_patients)
      permutations = []
      range_permutations = []
      
      # Find the reference we're talking about
      if reference.id == "MeasurePeriod"
        relative_time = Generator::hqmf.measure_period
      else
        data_criteria = Generator::hqmf.data_criteria(reference.id)
      end
      
      binding.pry
      

      permutations
    end
  end
end