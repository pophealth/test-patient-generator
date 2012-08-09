module HQMF
  class Precondition
    # 
    #
    # @param [Array] base_patients
    # @return 
    def generate(base_patients)
      binding.pry
      # d = HQMF::Generator.hqmf.data_criteria(preconditions[2].preconditions[1].preconditions.first.reference.id)
      
      if conjunction?
        # Include the matching module to override our generation functions
        conjunction_module = "Conjunction::#{self.conjunction_code.classify}"
        conjunction_module = conjunction_module.split('::').inject(Kernel) {|scope, name| scope.const_get(name)}

        extend conjunction_module
        generate(base_patients)
      elsif reference
        data_criteria = HQMF::Generator.hqmf.data_criteria(reference.id)
        data_criteria.generate(base_patients)
      end
    end
  end
end
