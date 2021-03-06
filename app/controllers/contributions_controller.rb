class ContributionsController < ApplicationController

  def show
    @contribution = Contribution.find(params[:id])
  end

  def index
    show_per_page = 10
    @contributions = Contribution.
        where(:analyzed => true, :approved => true).
        desc(:created_at).
        offset(show_per_page*params[:page].to_i).
        limit(show_per_page)
  end

  def analyze
    @contribution = Contribution.find(params[:id])
    if @contribution
      @contribution.languages = params[:languages]
      @contribution.technologies = params[:technologies]
      @contribution.features = params[:features]
      @contribution.concepts = params[:concepts]
      @contribution.analyzed = true
      @contribution.save!
      Mailer.analyzed_contribution(@contribution).deliver
    end
    render nothing: true
  end

  def create
    if !current_user
      flash[:notices] = 'You need to be logged in, if you want to make contribution'
      go_to_previous_page
      return
    end

    # TODO: check errors of input
    @contribution = Contribution.new
    @contribution.url = 'https://github.com/' + params[:contrb_repo_url].first + '.git'
    @contribution.title = params[:contrb_title]

    # set folder to '/' if no folder given
    folder = params[:contrb_folder]
    puts folder
    if folder.empty?
      folder = '/'
    end
    @contribution.folder = folder

    @contribution.description = params[:contrb_description]
    @contribution.user = current_user
    @contribution.save

    # create page for contribution
    # TODO: check owning the page?
    page = Page.find_by_full_title 'Contribution:'+Page.unescape_wiki_url(@contribution.title)
    # page already exist
    if page
      flash[:notice] = 'Wikipage for this contribution already exist'
      redirect_to '/contribute' and return
    end

    page = Page.find_or_create_page 'Contribution:'+Page.unescape_wiki_url(@contribution.title)
    page.users << current_user
    page.save!
    @contribution.approved = true
    @contribution.analyzed = true
    @contribution.page = page
    @contribution.save

    # send request to matching service
    #@contribution.analyse_request "http://101companies.org/contribute/analyze/#{@contribution.id}"

    # request was executed without errors
    if !request.nil?
      flash[:notice] = "You have created new contribution. "+
          "Please wait until it will be analyzed and approved by gatekeeper."
      Mailer.created_contribution(@contribution).deliver
    end

    redirect_to  action: "index"
  end

  def new
    # if not logged in -> show intro and go out
    if !current_user
      render 'contributions/login_intro' and return
    end

    @user_github_repos = nil

    begin
      # retrieve all repos of user
      @user_github_repos = (Octokit.repos current_user.github_name, {:type => 'all'}).map do |repo|
        # retrieve 'username/reponame' from url
        repo.clone_url.to_s[19..-5]
      end
    rescue
      flash[:warning] = "We couldn't retrieve you github information, please try in 5 minutes." +
          "If you haven't added github public email - please do it!"
      redirect_to '/contribute'
    end

  end

end
