module TPG
  module Patient
    class Generator
      # Generate patients from an HQMF file and its matching value sets file. These patients are designed to test all
      # paths through the logic of this particular clinical quality measure. The non-relevant demographic info
      #
      # @params [String] hqmf_path The location of an HQMF file that we will parse
      # @params [String] value_set_path THe location of an XLS or XLSX value set file that we will parse
      # @return An array of Records tailored to test the logic of a clinicial quality measure
      def self.patients_from_hqmf(hqmf_path, value_set_path)
        patients = []
        
        # Parse all of the value sets
        value_set_parser = HQMF::ValueSet::Parser.new()
        value_set_format ||= HQMF::ValueSet::Parser.get_format(value_set_path)
        value_sets = value_set_parser.parse(value_set_path, {format: value_set_format})

        # Parsed the HQMF file into a model
        codes_by_oid = HQMF2JS::Generator::CodesToJson.from_value_sets(value_sets) if (value_sets) 
        hqmf_contents = Nokogiri::XML(File.new hqmf_path).to_s
        hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1, codes_by_oid)

        # Create a base patient for the whole traversal
        base_patient = create_base_patient()
        
        binding.pry

        # We start with an empty patient and will build out many from each population.
        # At each step, we grow our base patient to represent the tree we've traversed so far.
        # Each recursive step will return an array that we merge into our patients.
        #patients.concat(generate_patients_from_preconditions(self.population_criteria["IPP"], base_patient))

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

        patients
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
          
        end
        
        if patient.gender.nil?
          # Set gender
          # Set first name based on that gender
        end
        
        # Some chance of death
        
        patient
      end
    end
  end
end