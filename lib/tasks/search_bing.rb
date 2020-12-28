module Intrigue
module Task
class SearchBing < BaseTask

  def self.metadata
    {
      :name => "search_bing",
      :pretty_name => "Search Bing",
      :authors => ["jcran"],
      :description => "This task hits the Bing API and finds related content. Discovered domains are created",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [{"type" => "String", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Make sure the key is set
    api_key = _get_task_config("bing_api_key")
    unless api_key
      _log_error "No api_key?"
      return
    end

    entity_name = _get_entity_name

    begin
      # Attach to the google service & search
      bing = Client::Search::Bing::SearchService.new(api_key)
      results = bing.search(entity_name)

      unless results && results["webPages"]
        _log_error "Unable to query... are you sure your api key is correct?"
        _log "Got response: #{results}"
        return
      end

      _log "Search returned #{results["webPages"]["value"].count} results"
      return unless results["webPages"]["value"].count > 0

      results["webPages"]["value"].each do |result|

        # Create the specific page
        _create_entity("Uri",     {   "name" => "#{result["displayUrl"]}",
                                      "uri" => "#{result["url"]}",
                                      "description" => result["name"],
                                      "source" => "Bing"
                                  })

      end # end results.each

    rescue SocketError => e
      _log_error "Unable to connect: #{e}"
    end

  end # end run()

end # end Class
end
end
