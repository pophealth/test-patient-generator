module HQMF
  class DataCriteria
    def generate_patients(base_patients)
      
    end
    
    def generate_to_pass(base_patients)
      permutations = []
      accessor = Kernel.get_const("Record")
      
      if property == :age
        # Our one and only special case
        permutations = value.generate_permutations_to_pass
        accessor = "birthdate="
        binding.pry
        
        base_patients
      else
        # We're dealing with a coded entry
        base_patients
      end
      
      new_patients = []
      base_patients.each do |patient|
        new_patient = Generator.extend_patient(patient)
        permutations.each do |permutation|
          p.send(accessor, permutation)
        end
        new_patients << new_patient
      end
      
      base_patients.concat(new_patients)
    end
    
    def generate_to_fail(base_patients)
      
    end
  end
end