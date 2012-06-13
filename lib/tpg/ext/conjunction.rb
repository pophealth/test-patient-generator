# These modules assume you are including them on a class that has preconditions
module Conjunction
  module AllTrue
    def generate_patients(base_patients)
      base_patients.concat(generate_to_pass(base_patients))
      base_patients.concat(generate_to_fail(base_patients))
    end
    
    def generate_to_pass(base_patients)
      self.preconditions.each do |precondition|
        base_patients.concat(precondition.generate_to_pass(base_patients))
      end
    end
    
    def generate_to_fail(base_patients)
      base_patients
    end
  end
  
  module AtLeastOneTrue
    def generate_patients(base_patients)
      self.preconditions.each do |precondition|
        
      end

      base_patients
    end
    
    def generate_to_pass(base_patients)
      
    end
    
    def generate_to_fail(base_patients)
      
    end
  end
end