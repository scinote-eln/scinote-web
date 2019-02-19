class JsonbHashSerializer
  def self.dump(hash)
    hash.nil? ? '{}' : hash.to_json
  end

  def self.load(hash)
    hash ||= {}
    hash = JSON.parse(hash) if hash.instance_of? String
    hash.with_indifferent_access
  end
end
