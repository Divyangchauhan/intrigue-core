module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "TODO"
    }
  end

  def validate_entity
    return (name =~ _dns_regex)
  end

  def primary
    false
  end

end
end
end