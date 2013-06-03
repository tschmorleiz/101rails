class PagesController < ApplicationController
  include PagesHelper
  require 'media_wiki'
  before_filter :check_uri
  respond_to :json, :html

  def check_uri
    # get page title
    full_title = params[:id]
    if full_title == nil
      return
    end
    # save params title
    full_title_wiki = full_title
    # convert to wiki-uri format, upcase for first char
    full_title = MediaWiki::send :upcase_first_char, (MediaWiki::wiki_to_uri full_title)
    # avoid endless loop for 'escaping/unenscaping' url during redirect_to by previous unescaping for title
    if full_title_wiki != CGI.unescape(full_title)
      redirect_to "/wiki/#{full_title}"
    end
  end

  def semantic_properties
   {'dependsOn'  => 'http://101companies.org/property/dependsOn',
     'instanceOf'  => 'http://101companies.org/property/instanceOf',
     'identifies'  => 'http://101companies.org/property/identifies',
     'linksTo'     => 'http://101companies.org/property/linksTo',
     'cites'       => 'http://101companies.org/property/cites',
     'uses'        => 'http://101companies.org/property/uses',
     'implements'  => 'http://101companies.org/property/implements',
     'instanceOf'  => 'http://101companies.org/property/instanceOf',
     'isA'         => 'http://101companies.org/property/isA',
     'developedBy' => 'http://101companies.org/property/developedBy',
     'reviewedBy'  => 'http://101companies.org/property/reviewedBy',
     'relatesTo'   => 'http://101companies.org/property/relatesTo' }
   end

  def page_to_resource(title)
    page = Page.find_or_create_page(title)
    if page.title.starts_with?('http')
      page.title
    else
      RDF::URI.new("http://101companies.org/resources/#{page.namespace.pluralize}/#{page.title}")
    end
  end

  def all
    respond_with all_pages
  end

  def get_rdf_graph(title)
     #   public static DEPENDS_ON = 'http://101companies.org/property/dependsOn'
     #   public static IDENTIFIES = 'http://101companies.org/property/identifies'
     #   public static LINKS_TO = 'http://101companies.org/property/linksTo'
     #   public static CITES = 'http://101companies.org/property/cites'
     #   public static USES = 'http://101companies.org/property/uses'
     #   public static IMPLEMENTS = 'http://101companies.org/property/implements'
     #   public static INSTANCE_OF = 'http://101companies.org/property/instanceOf'
     #   public static IS_A = 'http://101companies.org/property/isA'
     #   public static DEVELOPED_BY = 'http://101companies.org/property/developedBy'
     #   public static REVIEWED_BY = 'http://101companies.org/property/reviewedBy'
     #   public static RELATES_TO = 'http://101companies.org/property/relatesTo'
     #   public static LABEL = 'http://www.w3.org/2000/01/rdf-schema#label'
     #   public static PAGE = 'http://semantic-mediawiki.org/swivt/1.0#page'
     #   public static TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
     @page = Page.find_or_create_page(title)

     uri = self.page_to_resource title
     v101 = RDF::Vocabulary.new("http://101companies.org/property/")
     graph = RDF::Graph.new #<< [uri, RDF::RDFS.title, title]

     context   = RDF::URI.new("http://101companies.org")

     server = RDF::Sesame::Server.new RDF::URI("http://triples.101companies.org/openrdf-sesame")
     repository = server.repository("test")

     @page.semantic_links.each { |l|
      subject = uri
      predicate = RDF::URI.new(self.semantic_properties[l.split('::')[0]])
      object =  l.split('::')[1]
      statement =  RDF::Statement.new(subject, predicate, page_to_resource(object), :context => context)
      graph << statement
      #repository.delete statement
      #repository.insert statement
    }

    server = RDF::Sesame::Server.new RDF::URI("http://triples.101companies.org/openrdf-sesame")
    repository = server.repository("wiki101")
    title = title.sub(':', '-3A')
    res = repository.query(:object => RDF::URI.new("http://101companies.org/resource/#{title}"))
    res.each do |solution|
      graph << patch_resource(solution)
    end

    return graph
  end

  def patch_resource(resource)
    resource.subject.path.sub!('resource', 'resources')
    resource.object.path.sub!('resource', 'resources')

    resource.subject.path = patch_path(resource.subject.path)
    resource.object.path = patch_path(resource.object.path)
    resource
  end

  def patch_path(path)
    item = path.split("/").last
    fixed_item = item

    if (fixed_item.split('-3A').length == 2)
      ns = fixed_item.split('-3A')[0]
      title = fixed_item.split('-3A')[1]
      fixed_item = "#{ns.downcase.pluralize}/#{title}"
    else
      fixed_item = "concepts/#{fixed_item}"
    end

    path.sub!(item, fixed_item)
    path
  end

  def get_rdf
    title = params[:id]
    graph = self.get_rdf_graph(title)

    respond_with graph.dump(:ntriples)
  end

  def get_json
    title = params[:id]
    json = []
    rdf = self.get_rdf_graph(title)
    rdf.each do |resource|
      json.append ["#{resource.subject.scheme}://#{resource.subject.host}#{resource.subject.path}",
                    "#{resource.predicate.scheme}://#{resource.predicate.host}#{resource.predicate.path}",
                    resource.object.kind_of?(RDF::Literal) ? resource.object.object : "#{resource.object.scheme}:/#{resource.object.host}#{resource.object.path}", ]
    end
    respond_with json
  end

  def delete
    if current_user and (current_user.role=="admin")
      title = params[:id]
      page = Page.find_or_create_page(title)
      page.delete
      render :json => {:success => true} and return
    end
    render :json => {:success => false}
  end

  def show

    full_title = params[:id]

    if full_title.nil?
      full_title = "@project"
    end

    @page = Page.find_or_create_page full_title

    @page.instance_eval { class << self; self end }.send(:attr_accessor, "history")

    if not History.where(:page => full_title).exists?
      @page.history = History.create!(
        user: current_user,
        page: full_title,
        version: 1
        )
    else
      @page.history = History.where(:page => full_title).first
    end

    respond_to do |format|
      format.html { render :html => @page }
      format.json { render :json => {
        'id'        => @page._id,
        'idtitle'     => @page.full_title,
        'content' => @page.content,
        'title'     => @page.full_title,
        'sections'  => @page.sections,
        'history'   => @page.history.as_json(:include => {:user => { :except => [:role, :github_name]}}),
        'backlinks' => @page.backlinks
        }
      }
      end
  end

  def parse
    content = params[:content]
    full_title = params[:pagetitle]
    parsed_page = WikiCloth::Parser.new(:data => content, :noedit => true)
    parsed_page.sections.first.auto_toc = false
    page = Page.find_or_create_page full_title
    WikiCloth::Parser.context = page.namespace
    html = to_wiki_links(parsed_page)
    render :json => {:success => true, :html => html.html_safe}
  end

  def search
    @query_string = params[:q]
    if @query_string == ''
      redirect_to "/wiki/"
      flash[:notice] = 'Please write something, if you want to search something'
    else
      respond_with Page.gateway_and_login.search(@query_string)
    end
  end

  def summary
    begin
      # TODO: GC here???
      GC.disable
      full_title = params[:id]
      page = Page.find_or_create_page full_title
      render :json => {:sections => page.sections, :internal_links => page.internal_links}
    rescue
      @error_message="#{$!}"
      render :json => {:success => false, :error => @error_message}
    ensure
      GC.enable
      GC.start
    end
  end

  # get all sections for a page
  def sections
    begin
      full_title = params[:id]
      page = Page.find_or_create_page full_title
      sections = page.sections
      respond_with sections
    rescue
      @error_message="#{$!}"
      render :json => {:success => false, :error => @error_message}
    end
  end

  # get all internal links for the page
  def internal_links
    begin
      full_title = params[:id]
      page = Page.find_or_create_page(full_title)
      respond_with page.internal_links
    rescue
      @error_message="#{$!}"
      render :json => {:success => false, :error => @error_message}
    end
  end

  def update_history(pagename)
    if History.where(:page => pagename).exists?
      history = History.where(:page => pagename).first
      history.update_attributes(
        version: history.version + 1,
        user: current_user
        )
    else
      History.create!(
        page: pagename,
        version: 1,
        user: current_user
        )
    end
  end

  def update
    # check if operation is not permitted
    if cannot? :update, Page.create_or_find_page(params[:idtitle])
      render :json => {:success => false} and return
    end

    full_title = params[:idtitle]
    sections = params[:sections]
    content = params[:content]

    if content == ""
      sections.each { |s| content += s['content'] + "\n" }
    end

    page = Page.find_or_create_page(full_title)

    page.change(content)

    update_history(title)
    if full_title != params[:title]
      rename
    else
      render :json => {:success => true}
    end

  end

  def rename
    begin
      new_full_title = params[:title]
      page = Page.find_or_create_page(params[:idtitle])
      page.rename(new_full_title)
      update_history(new_full_title)
      render :json => {:success => true, :newtitle => new_full_title}
    rescue MediaWiki::APIError
      @error_message="#{$!.info}"
      render :json => {:success => false, :error => @error_message}, :status => 409
    end
  end

  def section
    full_title = params[:id]
    p = Page.find_or_create_page(full_title)
    section = {'content' => p.section(params[:full_title])}
    respond_with section.to_json
  end
end

