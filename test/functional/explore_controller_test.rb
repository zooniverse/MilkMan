require 'test_helper'

class ExploreControllerTest < ActionController::TestCase
  test "should get index" do
    Classification.create! created_at: Time.now
    get :index
    assert_response :success
  end

end
