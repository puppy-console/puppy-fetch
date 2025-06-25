require 'json'
require 'open-uri'
require 'base64'
require 'fileutils'

class GithubAPI 
    BASE_URL = "https://api.github.com"
    
    CURRENT_USER_URL = "#{BASE_URL}/user"
    AUTHORIZATIONS_URL = "#{BASE_URL}/authorizations"
    CODE_SEARCH_URL = "#{BASE_URL}/search/code?q={query}{&page,per_page,sort,order}"
    COMMIT_SEARCH_URL = "#{BASE_URL}/search/commits?q={query}{&page,per_page,sort,order}"
    EMAILS_URL = "#{BASE_URL}/user/emails"
    EMOJIS_URL = "#{BASE_URL}/emojis"
    EVENTS_URL = "#{BASE_URL}/events"
    FEEDS_URL = "#{BASE_URL}/feeds"
    FOLLOWERS_URL = "#{BASE_URL}/followers"
    FOLLOWING_URL = "#{BASE_URL}/following{/target}"
    GISTS_URL = "#{BASE_URL}/gists{/gist_id}"
    HUB_URL = "#{BASE_URL}/hub"
    ISSUE_SEARCH_URL = "#{BASE_URL}/search/issues?={query}{&page,per_page,sort,order}"
    ISSUES_URL = "#{BASE_URL}/issues"
    KEYS_URL = "#{BASE_URL}/user/keys"
    LABEL_SEARCH_URL = "#{BASE_URL}/labels?q={query}&repository_id={repository_id}{&page,per_page}"
    NOTIFICATIONS_URL = "#{BASE_URL}/notifications"
    ORGANIZATION_URL = "#{BASE_URL}/orgs/{org}"
    ORGANIZATION_REPOSITORIES_URL = "#{ORGANIZATION_URL}/repos{?type,page,per_page,sort}"
    ORGANIZATION_TEAMS_URL = "#{ORGANIZATION_URL}/teams"
    PUBLIC_GISTS_URL = "#{BASE_URL}/gists/public"
    RATE_LIMIT_URL = "#{BASE_URL}/rate_limit"
    REPOSITORY_URL = "#{BASE_URL}/repos/{owner}/{repository}"
    REPOSITORY_SEARCH_URL = "#{BASE_URL}/search/repositories?q={query}{&page,per_page,sort,order}"
    CURRENT_USER_REPOSITORIES_URL = "#{CURRENT_USER_URL}/repos{?type,page,per_page,sort}"
    STARRED_URL = "#{CURRENT_USER_URL}/starred{/owner}{/repo}"
    STARRED_GISTS_URL = "#{BASE_URL}/gists/starred"
    TOPIC_SEARCH_URL = "#{BASE_URL}/search/topics?q={query}{&page,per_page}"
    USER_URL = "#{BASE_URL}/users/{user}"
    USER_ORGANIZATIONS_URL = "#{BASE_URL}/user/orgs"
    USER_REPOSITORIES_URL = "#{BASE_URL}/users/{user}/repos{?type,page,per_page,sort}"
    USER_SEARCH_URL = "#{BASE_URL}/search/users?q={query}{&page,per_page,sort,order}"
    
    def initialize(auth_token = nil)
        @auth_token = auth_token
    end

    def uri_open_safe(uri, headers=nil)
        begin
            return URI.open(uri, headers || {})
        rescue => _
            return nil
        end
    end

    def http_get(uri, headers = nil)
        uri_content = uri_open_safe(uri, headers)
        if uri_content
            return JSON.parse(uri_content.read)
        else
            return nil
        end
    end

    def http_get_absolute(endpoint = nil, replace_params = nil)
        if endpoint != nil
            if replace_params
                endpoint = GithubAPI.sub_route_params(endpoint, replace_params)
            end

            return http_get(endpoint, default_headers())
        end

        return nil
    end

    def http_get_relative(endpoint = nil)
        dest = if endpoint then "#{BASE_URL}/#{endpoint}" else BASE_URL end
        if @auth_token != nil
            return http_get(dest, default_headers())
        else
            return http_get(dest)
        end

        return nil
    end

    def self.default_headers()
        return {
            "X-Github-Api-Version" => "2022-11-28",
            "UserAgent" => "RubyScript",
            "Accept" => "application/vnd.github+json"
        }
    end

    def default_headers()
        headers = GithubAPI.default_headers()
        if @auth_token 
            headers["Authorization"] = "Bearer #{@auth_token}"
        end
        return headers
    end

    def self.sub_route_params(text, params)
        for param in params 
            text = text.sub(/\{.*?\}/, param) 
        end
        
        return text
    end
end

