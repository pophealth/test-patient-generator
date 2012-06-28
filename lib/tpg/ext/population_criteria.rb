module HQMF
  # Takes a population
  # Returns a new population
  class PopulationCriteria
    def generate(base_patients)
      
    end
    
    def generate_pass(base_patients)
      
    end
    
    def generate_fail(base_patients)
      
    end
    
    def generate_match(base_patients)
      # All population criteria begin with a single conjunction precondition
      preconditions.first.generate_match(base_patients)
    end
    
    private
    
    def generate_permutations(base_patients)
      
    end
  end
end