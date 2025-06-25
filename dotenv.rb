def load_dotenv
    File.foreach('.env') do |line|
        var = line.strip.split('=', 2) 
        var_key = var[0]
        var_val = var[1]
        ENV[var_key]=var_val
    end
end


