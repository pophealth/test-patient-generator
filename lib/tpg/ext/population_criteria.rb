module HQMF
  class PopulationCriteria
    def generate_patients(base_patients)
      conjunction_module = "Conjunction::#{self.conjunction_code.classify}"
      conjunction_module = conjunction_module.split('::').inject(Kernel) {|scope, name| scope.const_get(name)}

      extend conjunction_module
      base_patients.concat(generate_patients(base_patients))
    end
  end
end