require 'optparse'

OPTIONS = {
    'branch-regex' => /^(main|\d+\.\d+)$/,
    'show-rate-limit' => false,
    'verbose' => false,
}

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
"\e[33mUsage\e[0m: ruby #{$0} GITHUB-OWNER GITHUB-REPO [options]"

parser = OptionParser.new do |opts|
    opts.banner = banner
    
    opts.separator ''
    opts.on('-X', '--branch-regex <regex>', Regexp, "filter branches in source.") { |o| OPTIONS['branch-regex'] = o }
    opts.on('-x', '--file-regex <regex>', Regexp, "filter files in source.") { |o| OPTIONS['file-regex'] = o }
    opts.on('-s', '--src <source>', 'sets the source to fetch from, if the directory/file is unavailable in the branch it is not cloned.') { |o| OPTIONS['source'] = o }
    opts.on('-d', '--dest <destination>', 'sets the destination location to clone the files to.' ) { |o| OPTIONS['destination'] = o }
    opts.on('-t', '--github-token', 'uses a github personal access token to authenticate, highly recommended.') { |o| ENV['GITHUB_TOKEN'] = o }
    opts.on('--show-rate-limit', 'shows rate limit usage on program exit.') { |o| OPTIONS['show-rate-limit'] = true }
    opts.on('-v', '--verbose', 'more program logs at runtime.') { |o| OPTIONS['verbose'] = true }
    opts.separator ''
end

parser.parse!

if ARGV.length != 2
    puts parser
    exit
end