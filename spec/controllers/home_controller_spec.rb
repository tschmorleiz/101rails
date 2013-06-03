require "spec_helper"

describe HomeController do

  describe "opening landing page" do
    it "doesn't make any error" do
      get :index
      response.should be_success
    end
  end

end
