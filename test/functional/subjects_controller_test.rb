require 'test_helper'

class SubjectsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show" do
    Subject.create! created_at: Time.now, zooniverse_id: "1", "metadata" => {"size" => "100x100"}
    get :show, zoo_id: "1"
    assert_response :success
  end

end
