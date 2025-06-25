def clone_tree(api, tree, path, file_regex=nil, verbose=false)
    return if !tree
    threads = tree.map do |item|
        Thread.new do
            item_path = item['path']
            item_type = item['type']
            
            if file_regex && !file_regex.match(item_path) && item_type == 'blob' then next end
                
            if !Dir.exist? path then FileUtils.mkdir_p path end
            clone_item(api, item, path, file_regex, verbose)
        end
    end
    threads.each(&:join)
end

def clone_item(api, item, path, file_regex=nil, verbose=false)
    case item['type']
        when 'tree'
            puts "Creating #{path}/#{item['path']} ... !" if verbose
            tree_head = api.http_get_absolute(item['url'])
            return if !tree_head
            tree = tree_head['tree']
            clone_tree(api, tree, "#{path}/#{item['path']}", file_regex, verbose)
        when 'blob'
            if !Dir.exist? path then FileUtils.mkdir_p "#{path}/#{item['path']}" end
            puts "Writing #{path}/#{item['path']} ... !" if verbose
            blob = api.http_get_absolute(item['url'])
            return if !blob
            File.write("#{path}/#{item['path']}", Base64.decode64(blob['content']))
    end
end

def search_for_source(api, tree, path)
    sources = path.split('/')
    return if sources.length == 0
    looking_for = sources.shift

    source_info = tree.find { |item| looking_for == item['path'] && item['type'] == 'tree'}
    return if !source_info
    source_head = api.http_get_absolute(source_info['url'])
    return if !source_head
    source = source_head['tree']

    return [source_info['path'], source] if sources.length == 0
    search_for_source(api, source, sources.join('/'))
end
