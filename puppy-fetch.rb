require 'fileutils'
require 'base64'
require 'benchmark'
require './dotenv'
require './gh-api'
require './gh-api-utils'
require './json-appends'
require './puppy-fetch-options'

require 'net/http'
require 'uri'

using JsonArray
using JsonHash

if File.exist? '.env' then load_dotenv() end 

AUTH_WARNING = \
"\nWarning: You are severely rate limited if you don't authorize with an access token.\n" \
"Get an access token: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens\n" \
"\n" \
"Options:\n" \
"\t - Create a .env file and add this to the file, 'GITHUB_TOKEN=YOUR_TOKEN', replace 'YOUR_TOKEN' with your access token. (***RECOMMENDED***)\n" \
"\t - Set a GITHUB_TOKEN environment variable in your current shell session or globally.\n" \
"\t - Set the --github-token flag when running.\n\n" \

puts AUTH_WARNING if !ENV['GITHUB_TOKEN']

github_token = ENV['GITHUB_TOKEN']
api = GithubAPI.new(github_token)

owner_id = ARGV[0]
repo_id = ARGV[1]
branch_regex = OPTIONS['branch-regex']
file_regex = OPTIONS['file-regex']
source = OPTIONS['source']
destination = OPTIONS['destination']
show_rate_limit = OPTIONS['show-rate-limit']
verbose = OPTIONS['verbose']

time = Benchmark.measure do
    repo = api.http_get_absolute(GithubAPI::REPOSITORY_URL, [owner_id, repo_id])
    fail "Unable to locate owner/repo, try again." if !repo
    
    branches = api.http_get_absolute(repo['branches_url'], [""])
    fail "Unable to get branches, try again." if !branches
    
    threads = branches.map do |branch|
        Thread.new do
            branch_name = branch['name']
        
            if branch_regex.match(branch_name)
                branch_sha = branch['commit']['sha']
                puts "Getting file(s) from (#{branch_sha}) - '#{branch_name}'... "
        
                branch_head_request = api.http_get_absolute(repo['trees_url'], ["/#{branch_sha}"])
                if !branch_head_request
                    STDERR.puts "Unable to get branch head for #{branch_name}."
                    next 
                end
                branch_head = branch_head_request['tree']
                
                if source
                    source_name, source_result = search_for_source(api, branch_head, source)

                    final_destination = if destination then 
                        "#{destination}/#{branch_name}/#{source_name}" 
                    else 
                        "#{branch_name}/#{source_name}" 
                    end

                    clone_tree(api, source_result, final_destination, file_regex, verbose)
                else
                    final_destination = if destination then "#{destination}/#{branch_name}" else branch_name end
                    clone_tree(api, branch_head, final_destination, file_regex, verbose)
                end
            end
        end
    end
    
    threads.each(&:join)
    
    rate_limit = api.http_get_absolute(GithubAPI::RATE_LIMIT_URL)['rate']
    rate_limit_max = rate_limit['limit']
    rate_limit_cur = rate_limit['remaining']
    rate_limit_res = Time.at(rate_limit['reset']).strftime("%I:%M %p")
    
    puts "\nRate Limit (#{rate_limit_cur}/#{rate_limit_max}) --- Resets at: [#{rate_limit_res}]" if show_rate_limit
end

puts "Finished cloning in ... #{'%.2f' % time.real}s !"