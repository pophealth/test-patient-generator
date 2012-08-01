module HQMF
  class Range
    def clone
      Range.new(type.try(:clone), low.try(:clone), high.try(:clone), width.try(:clone))
    end
    
    def merge(range, operation)
      
    end
    
    def apply_pq(ivl_pq)
      
    end
    
    def join(ivl_ts, operation)
      
    end
    
    def self.merge_ranges(range1, range2, operation)
      return nil if range1.nil? && range2.nil?
      return range1 if range2.nil?
      return range2 if range1.nil?
      
      type = range1.type == "PQ" && range2.type == "PQ" ? "IVL_PQ" : "IVL_TS"
      low = Value.merge_values(range1.low, range2.low)
      high = Value.merge_values(range1.high, range2.high)
      width = nil
      
      Range.new(type, low, high, width)
    end
  end
end