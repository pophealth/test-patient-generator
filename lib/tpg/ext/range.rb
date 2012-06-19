module HQMF
  class Range
    def generate_permutations
      permutations = []
      
      permutations.concat(generate_permutations_to_pass)
      permutations.concat(generate_permutations_to_fail)
      
      permutations
    end
    
    def generate_permutations_to_pass(start_modifier, end_modifier)
      permutations = []
      
      
      
      permutations.concat(low.generate_permutations(1)) if low
      permutations.concat(high.generate_permutations(-1)) if high
      
      permutations
    end
    
    def generate_permutations_to_fail
      permutations = []
      
      permutations.concat(low.generate_permutations(1)) if low
      permutations.concat(high.generate_permutations(-1)) if high
      
      permutations
    end
  end
end