module Conjunction
  module AllTrue
    def generate(base_patients)
      self.preconditions.each do |precondition|
        precondition.generate(base_patients)
      end
    end
  end
  
  module AtLeastOneTrue
    def generate(base_patients)
      self.preconditions.sample.generate(base_patients)
    end
  end
end