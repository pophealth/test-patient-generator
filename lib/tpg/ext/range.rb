module HQMF
  class Range
    def self.negotiate_ranges(range1, range2)
      
    end
    
    def self.merge_ranges(range1, range2)
      return nil if range1.nil? && range2.nil?
      return range1 if range2.nil?
      return range2 if range1.nil?
      
      type = range1.type == "PQ" && range2.type == "PQ" ? "IVL_PQ" : "IVL_TS"
      low = Value.merge_values(range1.low, range2.low, -1)
      high = Value.merge_values(range1.high, range2.high, 1)
      width = nil
      
      Range.new(type, low, high, width)
    end
    
    def generate_permutations(low_modifier, high_modifier)
      permutations = []
      
      # Generate permutations for high and low Values. Default to a list with one nil element if the value itself is nil
      low_permutations = low ? low.generate_permutations(low_modifier) : [nil]
      high_permutations = high ? high.generate_permutations(high_modifier) : [nil]
      
      low_permutations.each do |low_value|
        high_permutations.each do |high_value|
          permutations << Range.new(type, low_value, high_value, width)
        end
      end
      
      permutations
    end
  end
end