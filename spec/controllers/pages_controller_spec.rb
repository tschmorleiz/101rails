require "spec_helper"

describe PagesController do

  describe "get wiki-page with Monad article" do
    it "render Monad wiki page" do
      get :show, :full_title => 'Monad'
      response.should be_success
    end
  end


end
