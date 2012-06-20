module HQMF
  class Range
    def generate_permutations

    end
    
    def generate_permutations_to_pass(low_modifier, high_modifier)
      permutations = []
      
      # Generate permutations for high and low Values. Default to a list with one nil element if the value itself is nil
      low_permutations = low ? low.generate_permutations(low_modifier) : [nil]
      high_permutations = high ? high.generate_permutations(high_modifier) : [nil]
      
      low_permutation.each do |low_value|
        high_permutation.each do |high_value|
          permutations << Range.new(low: low_value, high: high_value)
        end
      end
      
      permutations
    end
    
    def generate_permutations_to_fail
      
    end
  end
end