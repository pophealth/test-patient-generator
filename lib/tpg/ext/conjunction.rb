module Conjunction
  module AllTrue
    # 
    #
    # @param [Array] base_patients
    # @return 
    def generate(base_patients)
      self.preconditions.each do |precondition|
        precondition.generate(base_patients)
      end
    end
  end
  
  # 
  #
  # @param [Array] base_patients
  # @return 
  module AtLeastOneTrue
    def generate(base_patients)
      self.preconditions.sample.generate(base_patients)
    end
  end
end