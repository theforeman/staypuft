require 'test_plugin_helper'

class StaypuftTest < ActiveSupport::TestCase
  setup do
    User.current = User.admin
  end

  test "the truth" do
    assert true
  end

end
