module HQMF
  class DataCriteria
    def generate_patients(base_patients)
      
    end
    
    def generate_permutations
      
    end
    
    def generate_to_pass(base_patients)
      accessor = "birthdate="

      potential_times = []
      temporal_references.each do |reference|
        base_patients.concat(reference.generate_patients_to_pass)
        potential_times.concat(reference.generate_permutations_to_pass)
      end
      
      # Derive what kind of coded entry we're looking at
      value_set = Generator::value_sets[Generator::value_sets.index{|value_set| value_set["oid"] == code_list_id}]
      entry = standard_category.classify.constantize.new
      
      # Create patients with each permutation of the coded entry
      new_patients = []
      base_patients.each do |patient|
        new_patient = Generator.extend_patient(patient)
        potential_times.each do |time|
          new_patient.send(accessor, entry)
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