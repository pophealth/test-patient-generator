module TPG
  class Generator
    attr_reader :patients
    attr_reader :visiting_prefix
    
    def initialize(traverser)
      @visiting_prefix = "generate_from"
      @traverser = traverser
      
      @patients = []
      @base_patient = Generator.create_base_patient()
    end
    
    # Generate patients from an HQMF file and its matching value sets file. These patients are designed to test all
    # paths through the logic of this particular clinical quality measure. The non-relevant demographic info
    def self.generate_patients(hqmf, value_sets)
      traverser = TPG::Traverser.new(hqmf, value_sets)
      generator = TPG::Generator.new(traverser)
      
      traverser.attach_visitors(generator)
      traverser.traverse()
      
      generator.patients
      
      #patients.concat(@traverser.traverser_preconditions(hqmf.population_criteria("IPP"), base_patient))

      # For every IPP base patient who potentially qualifies for the denominator, continue to recursively define all permutations
      # patients.each do |patient|
      #       if patient.final_destination.nil?
      #         patients.concat(generate_patients_from_preconditions(self.population_criteria["DENOM"], patient))
      #       end
      #     end

      # For every DENOM base patient who potentially qualifies for the numerator, continue to recursively define all permutations
      # patients.each do |patient|
      #       if patient.final_destination.nil?
      #         patients.concat(generate_patients_from_preconditions(self.population_criteria["NUMER"], patient))
      #       end
      #     end
    end
    
    # Create a patient with trivial demographic information and no coded entries.
    #
    # @return A Record with a blank slate
    def self.create_base_patient
      patient = Record.new
      patient.final_destination = nil
      patient.final_destination_reason = nil
      
      patient = Randomizer.attach_random_demographics(patient)
    end
    
    # Take an existing patient with some coded entries on them and redefine their trivial demographic information
    #
    # @param [Record] The patient that we're using as a base to create a new one
    # @return A new Record with an identical medical history to the given patient but new trivial demographic information
    def self.extend_patient(base_patient)
      patient = base_patient.clone()
      
      patient = Randomizer.attach_random_demographics(patient)
    end
    
    # Fill in any missing details that should be filled in on a patient. These include: age, gender, and first name
    #   
    def self.finalize_patient(patient)
      if patient.birthdate.nil?
        patient.birthdate = Time.now.to_i
      end
      
      if patient.gender.nil?
        # Set gender
        rand(2) == 0 ? patient.gender = "M" : patient.gender = "F"
        patient.first = Randomizer.randomize_first_name(patient.gender)
      end
      
      # Some chance of death
      
      patient
    end
    
    def generate_from_population(population)

    end
  end
end