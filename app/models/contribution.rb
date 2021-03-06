class Contribution

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia

  field :url, type: String
  field :title, type: String
  field :description, type: String
  field :folder, type: String, :default => '/'

  field :analyzed, type: Boolean, :default => false
  field :approved, type: Boolean, :default => false

  field :languages, type: Array
  field :technologies, type: Array
  field :concepts, type: Array
  field :features, type: Array

  before_validation :contribution_url_folder_proc
  def contribution_url_folder_proc
    self.contribution_url_folder = self.url.to_s + ':' + self.folder.to_s
  end

  # this field is using for validating the uniqueness of paar url+folder
  field :contribution_url_folder, type: String

  belongs_to :user
  has_one :page

  validates_uniqueness_of :title
  validates_uniqueness_of :contribution_url_folder

  validates_presence_of :title, :url, :folder

  attr_accessible :user_id, :title, :description, :url, :folder, :approved, :analyzed, :page_id

  def analyse_request(backping_url)
    success = true
    # TODO: check fail case
    # TODO: stress case?
    begin
      HTTParty.new.post 'http://worker.101companies.org/services/analyzeSubmission',
         :body => {
           :url => self.url,
           :folder => self.folder,
           :name => self.title,
           :backping => backping_url
         }.to_json,
         :headers => {'Content-Type' => 'application/json'}
    rescue
      flash[:error] = "Request on analyze service wasn't successful. Please retry it later"
      success = false
    end
    success
  end

  def self.array_to_string(array)
    if !array.nil?
      array.collect {|u| u}.join ', '
    else
      'No information retrieved'
    end
  end

end
