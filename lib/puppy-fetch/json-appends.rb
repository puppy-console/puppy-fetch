class Array 
    def as_pretty_json()
        return JSON.pretty_generate(self)
    end
end

class Hash
    def as_pretty_json()
        return JSON.pretty_generate(self)
    end
end