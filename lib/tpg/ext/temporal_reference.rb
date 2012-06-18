module HQMF
  class TemporalReference
    def generate_patients(base_patient)
      
    end
    
    def generate_permutations_to_pass
      permutations = []
      
      #TYPES = ['DURING','SBS','SAS','SBE','SAE','EBS','EAS','EBE','EAE','SDU','EDU','ECW','SCW','CONCURRENT']
      #INVERSION = {'SBS' => 'EAE','EAE' => 'SBS','SAS' => 'EBE','EBE' => 'SAS','SBE' => 'EAS','EAS' => 'SBE','SAE' => 'EBS','EBS' => 'SAE'}
      
      case type
      when "SBS"
        permutations.concat(offset.generate_permutations(-1))
      when "DURING"
        permutations.concat(offset.generate_permutations(1))
      end

      permutations
    end
    
    def generate_to_fail(base_patient)
      binding.pry

      []
    end
  end
end