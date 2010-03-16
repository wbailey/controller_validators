require 'test_helper'

class TestController < ActionController::Base
  def xx( val )
    validate_numericality_of( val )
  end

  def xx!( val )
    validate_numericality_of!( val )
  end
end

class ControllerValidatorsTest < ActiveSupport::TestCase
  def setup
    @con = TestController.new
  end

  # Replace this with your real tests.
  test "number true false " do
    assert_false( @con.xx( 'wes' ) )
  end
end
