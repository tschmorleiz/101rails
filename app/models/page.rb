# -*- encoding : utf-8 -*-
require 'json'
require 'pp'
require 'media_wiki'
require 'wikicloth'

class Page

  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  #index({ title: 1 }, { unique: true, background: true })

  has_and_belongs_to_many :users

  belongs_to :contribution

  attr_accessible :user_ids, :title, :created_at, :updated_at, :contribution_id

  def create(title)

    @base_uri = 'http://mediawiki.101companies.org/api.php'

    # create a context from NS:TITLE
    @ctx = title.split(':').length == 2 ?
        {ns: title.split(':')[0].downcase, title: title.split(':')[1]} : {ns: 'concept', title: title.split(':')[0]}

    self.title = title

    # set title to page, if defined in db
    page_from_db = Page.where(:title => title).first
    if !page_from_db.nil?
      self.users = page_from_db.users
    else
      begin
        # else retrieve users from old wiki
        @base_uri = 'http://mediawiki.101companies.org/api.php'
        a = Mechanize.new
        # get all authors of page in json format, 500 last revisions
        authors= a.get @base_uri + "?action=query&prop=revisions&titles=#{title}&rvprop=user&rvlimit=500&format=json"
        # parse json
        authors = JSON.parse authors.body
        # retrieve body of data from response => all revisions
        authors = authors['query']['pages'].first[1]['revisions'].to_a.uniq
        # go through authors and assign to page
        authors.each do |author|
          old_wiki_user = OldWikiUser.where(:name => author['user']).first
          # if matched user from old wiki
          if !old_wiki_user.nil?
            # and we have matching user from new wiki
            if !old_wiki_user.user.nil?
              # add him to authors of this page
              self.users << old_wiki_user.user
            end
          end
        end
      rescue
        # TODO: some rescue message?
      end
      # save page to db
      self.save
    end

    @wiki = WikiCloth::Parser.new(:data => content, :noedit => true)
    WikiCloth::Parser.context = @ctx

    @html = Rails.cache.read(title + "_html")
    if (@html == nil)
      @html = @wiki.to_html
      @wiki.internal_links.each do |link|
        @html.gsub!("<a href=\"#{link}\"", "<a href=\"/wiki/#{link}\"")
        #html.gsub!(":Category:","/wiki/Category:")
     end
      #convert <p>http://foo.com</p> into <p><a href="http://foo.com">http://foo.com</a>
      #@html.gsub!(/\b([\w]+?:\/\/[\w]+[^ \"\r\n\t<]*)/i, '<a href="\1">\1</a>')
      Rails.cache.write(title + "_html", @html)
    end

    self

  end

  def content
    c = Rails.cache.read(self.title)

    if (c == nil)
      c = self.gateway.get(self.title)
      Rails.cache.write(title, c)
    end

    return c
  end

  def html
    @html
  end

  def wiki
    @wiki
  end

  def context
    @ctx
  end

  def redirect_target
    content.match(/#REDIRECT \[\[([^\[\]]+)\]\]/)[1]
  end

  def rewrite_internal_link(from, to)
    Rails.logger = Logger.new(STDOUT)
    logger.debug "Rewriting #{from} -> #{to} on #{self.title}"
    new_content = self.content
    normalized_content = content.gsub("_", " ")
    normalized_content.scan(/((\[\[:?)([^:\]\[]+::)?(#{Regexp.escape(from.gsub("_", " "))})(\s*)(\|[^\[\]]+)?(\]\]))/i) do |link|
      link[2] = link[2] || ""
      link[5] = link[5] || ""
      if link[3][0].downcase == link[3][0]
        to = to[0,1].downcase + to[1..-1]
      end
      old_link = link[0]
      new_link = link[1..2].join() + to.gsub("_", " ") + link[4..6].join()
      logger.debug "> Found #{old_link} -> #{new_link}"
      pos = normalized_content.index(old_link)
      new_content = new_content[0 .. pos - 1] + new_link + new_content[pos + old_link.length .. -1]
      normalized_content = new_content.gsub("_", " ")
    end
    change(new_content)
  end

  def rewrite_backlinks(to)
    backlinks.each do |backlink|
      bl_page = Page.new.create(backlink)
      bl_page.rewrite_internal_link(self.title, to)
    end
  end

  def change(content)
    Rails.cache.write(self.title, content)
    Rails.cache.delete(self.title + "_html")
    gw = self.gateway
    gw.login(ENV['WIKIUSER'], ENV['WIKIPASSWORD'])
    gw.edit(self.title, content)
  end

  def delete
    gw = self.gateway
    gw.login(ENV['WIKIUSER'], ENV['WIKIPASSWORD'])
    gw.delete(self.title)
    Rails.cache.delete(self.title + "_html")
    Rails.cache.delete(self.title)
    # TODO: remove from db page entity
  end

  def internal_links
    puts "internal_links "
    puts @wiki
    @wiki.internal_links
  end

  def sections
    sec = []
    @wiki.sections.first.children.each do |s|
      sec.push({'title' => s.title, 'content' => s.wikitext.sub(/\s+\Z/, "")})
    end
    sec
  end

  def categories
    @wiki.categories
  end

  def backlinks
    self.gateway.backlinks(self.title).map { |e| e.gsub(" ", "_")  }
  end

  def section(section)
    @wiki.sections.first.children.find { |s| s.title.downcase == section.downcase }
  end

  def gateway
    if @_gateway == nil
      @_gateway = MediaWiki::Gateway.new(@base_uri)
    else
      return @_gateway
    end
  end

end
