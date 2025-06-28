module DotENV
    def self.load()
        File.foreach('.env') do |line|
            var = line.strip.split('=', 2) 
            var_key = var[0]
            var_val = var[1]
            ENV[var_key]=var_val
        end
    end

    def self.exist?() return File.exist? '.env' end
end


