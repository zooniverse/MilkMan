require 'test_helper'

class WelcomeControllerTest < ActionController::TestCase
  test "should get index" do
    Classification.create! created_at: Time.now
    get :index
    assert_response :success
  end

end
