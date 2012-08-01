module HQMF
  class DerivationOperator
    def self.merge(set1, set2, operation)
      return [] if set1.empty? && set2.empty?
      return set1 if set2.empty?
      return set2 if set1.empty?

      result = []
      #01/2012 - 12/2012, 03/2012 - 05/2012, 04/2012 - 07/2012
      #02/2012 - 03/2012
      set1.each do |range1|
        set2.each do |range2|
          intersect = Range.merge_ranges(range1)
        end
        result << intersect unless intersect.nil?
      end
      
      result
    end
  end
end