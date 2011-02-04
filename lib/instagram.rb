require 'addressable/uri'
require 'addressable/template'
require 'net/http'
require 'instagram/models'

module Instagram
  
  extend self
  
	#ugly hack, need to write initialize function
	Login_params = {
								 'username'  => 'blank',
								 'password'  => 'blank',
								 'device_id' => '00000000'
  }

  Popular = Addressable::URI.parse 'http://instagr.am/api/v1/feed/popular/'
  UserFeed = Addressable::Template.new 'http://instagr.am/api/v1/feed/user/{user_id}/'
  UserInfo = Addressable::Template.new 'http://instagr.am/api/v1/users/{user_id}/info/'
  SearchUsers = Addressable::URI.parse 'http://instagr.am/api/v1/users/search/'
  SearchTags = Addressable::URI.parse 'http://instagr.am/api/v1/tags/search/'
  TagFeed = Addressable::Template.new 'http://instagr.am/api/v1/feed/tag/{tag}/'
  
  def popular(params = {}, options = {})
    parse_response(Popular.dup, params, options.fetch(:parse_with, Timeline))
  end
  
  def by_user(user_id, params = {}, options = {})
    url = UserFeed.expand :user_id => user_id
    parse_response(url, params, options.fetch(:parse_with, Timeline))
  end
  
  def user_info(user_id, params = {}, options = {})
    url = UserInfo.expand :user_id => user_id
    parse_response(url, params, options.fetch(:parse_with, UserWrap))
  end

	def search_users(query, params = {}, options = {})
		params = {:query => query}.merge(params)
		parse_post_response(SearchUsers.dup, params, options.fetch(:parse_with, UserSearchWrap))
  end
  
  def search_tags(query, params = {}, options = {})
    params = {:q => query}.merge(params)
    parse_response(SearchTags.dup, params, options.fetch(:parse_with, SearchTagsResults))
  end
  
  def by_tag(tag, params = {}, options = {})
    url = TagFeed.expand :tag => tag
    parse_response(url, params, options.fetch(:parse_with, Timeline))
  end
  
  private
  
  def parse_response(url, params, parser = nil)
    url.query_values = params
    body = get_url url
    parser ? parser.parse(body) : body
  end

  def get_url(url)
    response = Net::HTTP.start(url.host, url.port) { |http|
      http.get url.request_uri, 'User-agent' => 'Instagram Ruby client'
    }
    
    if Net::HTTPSuccess === response
      response.body
    else
      response.error!
    end
  end

  def parse_post_response(url, params, parser = nil)
		@cookie ||= login_user
    body = post_url(url, params,@cookie)
    #parser ? parser.parse(body) : body
  end

	def post_url(url, params,cookie)
		http = Net::HTTP.new(url.host, url.port)
		request = Net::HTTP::Post.new(url.request_uri)
		request['Cookie'] = cookie
		request['User-agent'] = "Instagram Ruby client"
		request.set_form_data(params)
		response = http.request(request)

		if Net::HTTPSuccess === response
			response.body
		else
			response.error!
		end
	end

	def login_user
		uri = Addressable::URI.parse 'https://instagr.am/api/v1/accounts/login/'
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Post.new(uri.request_uri)
		request['User-agent'] = "Instagram Ruby client"
		request.set_form_data(Login_params)
		response = http.request(request)

		response['set-cookie']
	end
  
end
