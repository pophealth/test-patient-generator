require 'test_helper'

# These tests are very coarse grained because they are testing randomizing functionality.
# Largely these unit tests will verify that we are getting at least some information, but does not exhaustively test that the random values are appropriate.
class RandomizerTest < MiniTest::Unit::TestCase
  def test_randomize_demographics

  end

  def test_randomize_race_and_ethnicity

  end

  def test_randomize_language

  end

  def test_randomize_first_name
    refute_nil HQMF::Randomizer.randomize_first_name("M")
    refute_nil HQMF::Randomizer.randomize_first_name("F")
  end

  def test_randomize_last_name
    refute_nil HQMF::Randomizer.randomize_last_name
  end

  def test_randomize_address
    address = HQMF::Randomizer.randomize_address
    expected = ["street", "city", "state", "postalCode"]

    # assert_equal address.size, expected.size
    # address.each do |key, value|
    #   assert expected.include? key
    #   refute_nil value
    # end
  end

  def test_randomize_birthdate
    
  end

  def test_randomize_range
    # range = HQMF::Randomizer.randomize_range(nil, nil)
    # binding.pry

    # low = Value.new()
    # range = HQMF::Randomizer.randomize_range(low, nil)
    # binding.pry

    # high = Value.new
    # range = HQMF::Randomizer.randomize_range(nil, high)
    # binding.pry

    # range = HQMF::Randomizer.randomize_range(low, high)
    # binding.pry    
  end

  def test_n_between
    betweens = HQMF::Randomizer.n_between(0, 100)
    betweens = JSON.parse(betweens)

    refute_empty betweens
  end

  def test_between
    between = HQMF::Randomizer.between(0, 100)
    refute_nil between
    assert between >= 0
    assert between <= 100
  end

  def test_percent
    refute_nil HQMF::Randomizer.percent(50)
    refute HQMF::Randomizer.percent(-1)
  end
end