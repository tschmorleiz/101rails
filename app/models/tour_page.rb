class TourPage
  include Mongoid::Document
  include Mongoid::Paranoia

  field :name, type: String
  field :sections, type: Array

  def create(name)
    self.title = name
  end

end
