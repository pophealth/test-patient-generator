module HQMF
  class TemporalReference
    def generate_patients(base_patients)
      
    end
    
    def generate_patients_to_pass(base_patients)
      
    end
    
    def generate_permutations_to_pass
      permutations = []
      range_permutations = []
      
      # Find the reference we're talking about
      if reference.id == "MeasurePeriod"
        relative_time = Generator::hqmf.measure_period
      else
        data_criteria = Generator::hqmf.data_criteria(reference.id)
      end
      
      binding.pry
      case type
      when "DURING"
        range_permutations = relative_time.generate_permutations()
      when "SBS" # Starts before start
        
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

      permutations
    end
    
    def generate_to_fail(base_patient)

    end
  end
end