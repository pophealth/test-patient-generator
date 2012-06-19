module HQMF
  class TemporalReference
    def generate_patients(base_patient)
      
    end
    
    def generate_permutations_to_pass
      permutations = []
      range_permutations = []
      
      # Find the reference we're talking about
      if reference.id == "MeasurePeriod"
        relative_time = Generator::hqmf.measure_period
      else
        relative_time = Generator::hqmf.data_criteria(reference.id)
      end
      
      
      #TYPES = ['DURING','SBS','SAS','SBE','SAE','EBS','EAS','EBE','EAE','SDU','EDU','ECW','SCW','CONCURRENT']
      #INVERSION = {'SBS' => 'EAE','EAE' => 'SBS','SAS' => 'EBE','EBE' => 'SAS','SBE' => 'EAS','EAS' => 'SBE','SAE' => 'EBS','EBS' => 'SAE'}
      
      
      case type
      when "DURING"
        
        relative_time
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
      binding.pry

      []
    end
  end
end