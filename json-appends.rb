module JsonArray
    refine Array do
        def as_pretty_json()
            return JSON.pretty_generate(self)
        end
    end
end

module JsonHash 
    refine Hash do
        def as_pretty_json()
            return JSON.pretty_generate(self)
        end
    end
end