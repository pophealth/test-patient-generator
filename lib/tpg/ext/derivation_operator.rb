module HQMF
  class DerivationOperator
    # Perform an intersection between two sets of Ranges (assuming these are timestamps).
    #
    # @param [Array] set1 One array of Ranges to be intersected.
    # @param [Array] set2 The other array of Ranges to be intersected.
    # @return A new array that contains the shared Ranges between set1 and set2.
    def self.intersection(set1, set2)
      # Special cases to account for emptiness
      return [] if set1.empty? && set2.empty?
      return set1 if set2.empty?
      return set2 if set1.empty?

      # Merge each element of the two sets together
      result = []
      set1.each do |range1|
        set2.each do |range2|
          intersect = range1.intersection(range2)
          result << intersect unless intersect.nil?
        end
      end
      
      result
    end
    
    # Perform a union between two sets of Ranges (assuming these are timestamps)
    #
    # @param [Array] set1 One array of Ranges to be unioned.
    # @param [Array] set2 The other array of Ranges to be unioned.
    # @return A new array tha contains the union of Ranges between set1 and set2.
    def self.union(set1, set2)
      # Special cases to account for emptiness
      return [] if set1.empty? && set2.empty?
      return set1 if set2.empty?
      return set2 if set1.empty?
      
      # Join each element of the two sets together
      result = []
      set1.each do |range1|
        set2.each do |range2|
          union = range1.union(range2)
          result.concat!(union)
        end
      end
      
      result
    end
  end
end