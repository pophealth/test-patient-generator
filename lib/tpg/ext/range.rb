module HQMF
  class Range
    def generate_permutations
      {}
    end
    
    def generate_permutations_to_pass
      permutations = []
      
      permutations.concat(low.generate_permutations_to_pass) if low
      permutations.concat(high.generate_permutations_to_pass) if high
      binding.pry
      
      permutations
    end
    
    def generate_permutations_to_fail
      []
    end
  end
end