require 'test_helper'

class PurchasesControllerTest < ActionDispatch::IntegrationTest
  test "should get receipt" do
    get purchases_receipt_url
    assert_response :success
  end

end
