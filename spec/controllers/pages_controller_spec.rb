require "spec_helper"

describe PagesController do

  describe "get wiki-page with Monad article" do
    it "render Monad wiki page" do
      visit '/wiki/Monad'
      response.should be_success
    end
  end

  describe "get wiki-page with @project article" do
    it "render @project wiki page" do
      visit '/wiki/@project'
      response.should be_success
    end
  end

end
