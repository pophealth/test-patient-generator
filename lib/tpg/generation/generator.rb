module HQMF
  # The generator will create as many patients as possible to exhaustively test the logic of a given clinical quality measure.
  class Generator
    # TODO - This is a hack and a half. Need a better way to resolve data_criteria from any point in the tree.
    class << self
      attr_accessor :hqmf
      attr_accessor :value_sets
    end
    
    # @param [HQMF::Document] hqmf A model representing the logic of a given HQMF document.
    # @param [Hash] value_sets All of the value sets referenced by this particular HQMF document.
    def initialize(hqmf, value_sets)
      @patients = []
      Generator.hqmf = hqmf
      Generator.value_sets = value_sets
    end
    
    # Generate patients from an HQMF file and its matching value sets file. These patients are designed to test all
    # paths through the logic of this particular clinical quality measure.
    def generate_patients
      base_patients = [Generator.create_base_patient]
      generated_patients = []
      
      #["IPP", "DENOM", "NUMER", "EXCL"]
      ["IPP", "DENOM", "NUMER", "EXCL"].each do |population|
        criteria = Generator.hqmf.population_criteria(population)
        
        # We don't need to do anything for populations with nothing specified
        if criteria.nil? || !criteria.preconditions.present?
          next
        else
          criteria.generate_match(base_patients)
        end
        
        base_patients.collect! do |patient|
          patient.elimination_population = population
          generated_patients.push(Generator.finalize_patient(patient))
          Generator.extend_patient(patient)
        end
      end
      
      generated_patients
    end
    
    # Create a patient with trivial demographic information and no coded entries.
    #
    # @return A Record with a blank slate
    def self.create_base_patient
      patient = Record.new
      patient.elimination_population = nil
      patient.elimination_reason = nil
      
      patient = Randomizer.randomize_demographics(patient)
    end
    
    # Take an existing patient with some coded entries on them and redefine their trivial demographic information
    #
    # @param [Record] base_patient The patient that we're using as a base to create a new one
    # @return A new Record with an identical medical history to the given patient but new trivial demographic information
    def self.extend_patient(base_patient)
      patient = base_patient.clone()
      Randomizer.randomize_demographics(patient)
    end
    
    # Fill in any missing details that should be filled in on a patient. These include: age, gender, and first name.
    #
    # @param [Record] patient The patient for whom we are about to fill in remaining demographic information.
    # @return A patient with guaranteed complete information necessary for standard formats.
    def self.finalize_patient(patient)
      if patient.birthdate.nil?
        patient.birthdate = Randomizer.randomize_birthdate(patient)
        patient.birthdate = Time.now.to_i
      end
      
      if patient.gender.nil?
        # Set gender
        patient.gender = "F"
        #rand(2) == 0 ? patient.gender = "M" : patient.gender = "F"
        patient.first = Randomizer.randomize_first_name(patient.gender)
      end
      
      patient
    end
    
    #
    #
    # @param [String] type 
    # @return 
    def self.classify_entry(type)
      # The possible matches per patientAPI function can be found in hqmf-parser's README
      case type
      when :allProcedures
        "procedures"
      when :proceduresPerformed
        "procedures"
      when :proceduresResults
        "procedures"
      when :laboratoryTests
        "vital_signs"
      when :allMedications
        "medications"
      when :activeDiagnoses
        "conditions"
      when :inactiveDiagnoses
        "conditions"
      when :resolvedDiagnoses
        "conditions"
      when :allProblems
        "conditions"
      when :allDevices
        "medical_equipment"
      else
        type.to_s
      end
    end
  end
end