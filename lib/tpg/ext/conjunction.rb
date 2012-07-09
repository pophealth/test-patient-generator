module Conjunction
  module AllTrue
    def generate(base_patients)
      base_patients.concat(generate_to_pass(base_patients))
      base_patients.concat(generate_to_fail(base_patients))
    end
    
    def generate_pass(base_patients)
      
    end
    
    def generate_fail(base_patients)
      
    end

    def generate_match(base_patients)
      self.preconditions.each do |precondition|
        precondition.generate_match(base_patients)
      end
    end
    
    private
    
    def generate_permutations(base_patients)
      
    end
  end
  
  module AtLeastOneTrue
    def generate(base_patients)

    end
    
    def generate_pass(base_patients)
      
    end
    
    def generate_fail(base_patients)
      
    end
    
    def generate_match(base_patients)
      self.preconditions.sample.generate_match(base_patients)
    end
    
    private
    
    def generate_permutations(base_patients)
      
    end
  end
end