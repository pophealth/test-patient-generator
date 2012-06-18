module HQMF
  class DataCriteria
    def generate_patients(base_patients)
      
    end
    
    def generate_to_pass(base_patients)
      permutations = []
      accessor = "birthdate="

      # Get the permutations of all fields on this criteria
      if property == :age
        
      else
        temporal_references.each do |reference|
          permutations.concat(reference.generate_permutations_to_pass)
        end
        binding.pry
      end
      
      # Derive what kind of coded entry we're looking at
      value_set = Generator::value_sets[Generator::value_sets.index{|value_set| value_set["oid"] == code_list_id}]
      entry = standard_category.classify.constantize.new      
      
      # Create patients with each permutation of the coded entry
      new_patients = []
      base_patients.each do |patient|
        new_patient = Generator.extend_patient(patient)
        permutations.each do |permutation|
          new_patient.send(accessor, permutation)
        end
        new_patients << new_patient
      end
      
      base_patients.concat(new_patients)
    end
    
    def generate_to_fail(base_patients)
      # First the case where the coded entry does not exist
      
      # Then give the entry but make temporal info (etc.) miss
    end
  end
end