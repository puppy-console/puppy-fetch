require 'fileutils'
require 'optionparser'
require_relative 'puppy-fetch/dotenv'
require_relative 'puppy-fetch/gh-api'
require_relative 'puppy-fetch/json-appends'

class PuppyFetch
    attr_accessor :api
    attr_accessor :settings
    attr_accessor :cli_mode

    Api = GithubApi

    AUTH_WARNING_NO_TOKEN = \
    "\e[0;33mWarning: You are severely rate limited if you don't authorize with an access token.\n" \
    "Get an access token: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens\n" \
    "\n" \
    "Options:\n" \
    "\t - Create a .env file and add this to the file, 'GITHUB_TOKEN=YOUR_TOKEN', replace 'YOUR_TOKEN' with your access token. (***RECOMMENDED***)\n" \
    "\t - Set a GITHUB_TOKEN environment variable in your current shell session or globally.\n" \
    "\t - Set the --github-token flag when running.\n\n\e[0m" \
    
    def self.has_dotenv?() return DotENV.exist? end
    def self.load_dotenv() return DotENV.load end
    def self.token() return ENV['GITHUB_TOKEN'] end
    def self.has_token?() return PuppyFetch.token end

    def self.assert(val, msg) fail msg if !val end
    def assert(val, msg) PuppyFetch.assert(val, msg) end

    def self.thread_process(collection, &fn)
        threads = collection.map do |item|
            thread = Thread.new { fn.call(item) }
            sleep(0.01)
            thread
        end
        threads.each(&:join)
    end
    
    def current_repo_name()
        return @current_repo['name']
    end

    def get_repo(owner=nil, repo=nil)
        owner = @settings.owner if @settings.owner && !owner 
        repo = @settings.repo if @settings.repo && !repo

        return nil if !owner || !repo
        return @api.http_get_absolute(Api::REPOSITORY_URL, [owner, repo])
    end 

    def get_branches(repo)
        return @api.http_get_absolute(repo['branches_url'])
    end

    def get_rate_limit()
        rate_limit_info = @api.http_get_absolute(Api::RATE_LIMIT_URL) 
        return rate_limit_info['rate'] if rate_limit_info 
        return nil
    end

    def initialize(settings)
        PuppyFetch.load_dotenv if PuppyFetch.has_dotenv?
        puts AUTH_WARNING_NO_TOKEN if !PuppyFetch.has_token?
        
        @api = Api.new(PuppyFetch.token)        
        @settings = settings

        puts "\e[0;32mAuthorized to '#{Api::BASE_URL}' successfully!\e[0m" if got_auth?
        puts "\e[0;31mCouldn't authorize to '#{Api::BASE_URL}'... malformed token.\e[0m" if bad_token?
    end

    def bad_token?() return !got_auth? && PuppyFetch.has_token? end
    def get_auth() return @api.http_get_absolute(Api::CURRENT_USER_URL) end
    def got_auth?() return get_auth end

    def get_rate_limit_pretty()
        rate_limit = get_rate_limit
        remaining_calls = "#{rate_limit['remaining']}/#{rate_limit['limit']}"
        reset_time = Time.at(rate_limit['reset']).strftime("%I:%M %p")

        puts "Rate Limit: (#{remaining_calls}) - Resets at #{reset_time}."
    end

    def self.as_cli()
        hero_banner_text = " [ #{File.basename($0, ".rb")} ]: a command-line tool to fetch intersections between branches and clone them ! "
        hero_banner_padding = ''.center(hero_banner_text.length, ' ')
        hero_banner_edge = ''.center(hero_banner_text.length, '~')

        banner = \
        "\n\e[33m" \
        "+ #{hero_banner_edge} +\n" \
        "| #{hero_banner_padding} |\n" \
        "| #{hero_banner_text} |\n" \
        "| #{hero_banner_padding} |\n" \
        "+ #{hero_banner_edge} +" \
        "\e[0m\n" \
        "\n" \
        "\e[33mUsage\e[0m: puppy-fetch GITHUB-OWNER GITHUB-REPO [options]"


        cli_settings = Settings.new
        cli_settings.branch_regex = /^(main|\d+\.\d+)$/
        cli_settings.verbose = false
        cli_settings.destination = "out"

        parser = OptionParser.new do |opts|
            opts.banner = banner
            
            opts.separator ''
            opts.on('-X', '--branch-regex <regex>', Regexp, "filter branches in source.") { |o| cli_settings.branch_regex = o }
            opts.on('-x', '--file-regex <regex>', Regexp, "filter files in source.") { |o| cli_settings.file_regex = o }
            opts.on('-s', '--src <source>', 'sets the source to fetch from, if the directory/file is unavailable in the branch it is not cloned.') { |o| cli_settings.source = o }
            opts.on('-d', '--dest <destination>', 'sets the destination location to clone the files to.' ) { |o| cli_settings.destination = o }
            opts.on('-t', '--github-token', 'uses a github personal access token to authenticate, highly recommended.') { |o| ENV['GITHUB_TOKEN'] = o }
            opts.on('-v', '--verbose', 'more program logs at runtime.') { |o| cli_settings.verbose = true }
            opts.separator ''
        end

        parser.parse!

        if ARGV.length != 2
            puts parser
            exit
        else
            cli_settings.owner = ARGV[0]
            cli_settings.repo = ARGV[1]
        end

        return cli_settings
    end

    class Settings
        attr_accessor :owner
        attr_accessor :repo
        attr_accessor :branch_regex
        attr_accessor :file_regex
        attr_accessor :source
        attr_accessor :destination
        attr_accessor :verbose
    end

    def clone_tree(tree, path, file_regex=nil, verbose=false)
        return if !tree
        threads = tree.map do |item|
            Thread.new do
                item_path = item['path']
                item_type = item['type']
                
                if file_regex && !file_regex.match(item_path) && item_type == 'blob' then next end
                    
                if !Dir.exist? path then FileUtils.mkdir_p path end
                clone_item(item, path, file_regex, verbose)
            end
        end
        threads.each(&:join)
    end

    def clone_item(item, path, file_regex=nil, verbose=false)
        case item['type']
            when 'tree'
                puts "Creating #{path}/#{item['path']} ... !" if verbose
                tree_head = api.http_get_absolute(item['url'])
                return if !tree_head
                tree = tree_head['tree']
                clone_tree(tree, "#{path}/#{item['path']}", file_regex, verbose)
            when 'blob'
                if !Dir.exist? path then FileUtils.mkdir_p "#{path}/#{item['path']}" end
                puts "Writing #{path}/#{item['path']} ... !" if verbose
                blob = @api.http_get_absolute(item['url'])
                return if !blob
                File.write("#{path}/#{item['path']}", Base64.decode64(blob['content']))
        end
    end

    def search_for_source(tree, path)
        sources = path.split('/')
        return if sources.length == 0
        looking_for = sources.shift

        source_info = tree.find { |item| looking_for == item['path'] && item['type'] == 'tree'}
        return if !source_info
        source_head = api.http_get_absolute(source_info['url'])
        return if !source_head
        source = source_head['tree']

        return [source_info['path'], source] if sources.length == 0
        search_for_source(@api, source, sources.join('/'))
    end
end




# time = Benchmark.measure do
#     fail "Unable to locate owner/repo, try again." if !repo
    
#     branches = api.http_get_absolute(repo['branches_url'], [""])
#     fail "Unable to get branches, try again." if !branches
    
#     threads = branches.map do |branch|
#         Thread.new do
#             branch_name = branch['name']
        
#             if branch_regex.match(branch_name)
#                 branch_sha = branch['commit']['sha']
#                 puts "Getting file(s) from (#{branch_sha}) - '#{branch_name}'... "
        
#                 branch_head_request = api.http_get_absolute(repo['trees_url'], ["/#{branch_sha}"])
#                 if !branch_head_request
#                     STDERR.puts "Unable to get branch head for #{branch_name}."
#                     next 
#                 end
#                 branch_head = branch_head_request['tree']
                
#                 if source
#                     source_name, source_result = search_for_source(api, branch_head, source)

#                     final_destination = if destination then 
#                         "#{destination}/#{branch_name}/#{source_name}" 
#                     else 
#                         "#{branch_name}/#{source_name}" 
#                     end

#                     clone_tree(api, source_result, final_destination, file_regex, verbose)
#                 else
#                     final_destination = if destination then "#{destination}/#{branch_name}" else branch_name end
#                     clone_tree(api, branch_head, final_destination, file_regex, verbose)
#                 end
#             end
#         end
#     end
    
#     threads.each(&:join)
    
#     rate_limit = api.http_get_absolute(GithubApi::RATE_LIMIT_URL)['rate']
#     rate_limit_max = rate_limit['limit']
#     rate_limit_cur = rate_limit['remaining']
#     rate_limit_res = Time.at(rate_limit['reset']).strftime("%I:%M %p")
    
#     puts "\nRate Limit (#{rate_limit_cur}/#{rate_limit_max}) --- Resets at: [#{rate_limit_res}]" if show_rate_limit
# end

# puts "Finished cloning in ... #{'%.2f' % time.real}s !"
