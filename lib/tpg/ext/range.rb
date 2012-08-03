module HQMF
  class Range
    # Perform a deep copy of this Range.
    #
    # @return A deep copy of this Range.
    def clone
      Range.new(type.try(:clone), low.try(:clone), high.try(:clone), width.try(:clone))
    end
    
    # Perform an intersection between this Range and the passed in Range.
    # There are three potential situations that can happen: disjoint, equivalent, or overlapping.
    #
    # @param [Range] range The other Range intersecting this. If it is nil it implies all times are ok (i.e. no restrictions).
    # @return A new Range that represents the shared amount of time between these two Ranges. nil means there is no common time.
    def intersection(range)
      # Return self if nil (the other range has no restrictions) or if it matches the other range (they are equivalent)
      return self.clone if range.nil?
      return self.clone if eql?(range)

      # Figure out which range starts later (the more restrictive one)
      if low <= range.low
        earlier_start = self
        later_start = range
      else
        earlier_start = range
        later_start = self
      end
      
      # Return nil if there is no common time (the two ranges are entirely disjoint)
      return nil unless later_start.contains?(earlier_start.high)
      
      # Figure out which ranges ends earlier (the more restrictive one)
      if high >= range.high
        earlier_end = self
        later_end = range
      else
        earlier_end = range
        later_end = self
      end

      Range.new("TS", later_start.low.clone, earlier_end.high.clone, nil)
    end
    
    # 
    #
    # @param [Range] range 
    # @return
    def union(range)
      
    end
    
    # 
    #
    # @param [Range] ivl_pq
    # @return
    def apply_pq(ivl_pq)
      
    end
    
    # 
    #
    # @param [Range] range1 
    # @param [Range] range2 
    # @return 
    def self.merge_ranges(range1, range2)
      return nil if range1.nil? && range2.nil?
      return range1 if range2.nil?
      return range2 if range1.nil?
      
      type = range1.type == "PQ" && range2.type == "PQ" ? "IVL_PQ" : "IVL_TS"
      low = Value.merge_values(range1.low, range2.low)
      high = Value.merge_values(range1.high, range2.high)
      width = nil
      
      Range.new(type, low, high, width)
    end
    
    # Check to see if a given value falls within this Range's high and low.
    #
    # @param [Value] value The value that may or may not fall within the range.
    # @return True if the value is contained. Otherwise, false.
    def contains?(value)
      start_time = low.to_time_object
      end_time = high.to_time_object
      time = value.to_time_object
      
      time.between?(start_time, end_time)
    end
    
    # Check to see if a given Range's low and high matches this' low and high.
    #
    # @param [Range] range The Range to which we're comparing.
    # @return True if the given range starts and ends at the same time as this. Otherwise, false.
    def eql?(range)
      return false if range.nil? || low.nil? || range.low.nil? || high.nil? || range.high.nil?
      
      return low.value == range.low.value && low.inclusive? == range.low.inclusive? &&
             high.value == range.high.value && high.inclusive? == range.high.inclusive?
    end
  end
end