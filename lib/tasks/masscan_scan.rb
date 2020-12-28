###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
module Task
class Masscan < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "masscan_scan",
      :pretty_name => "Masscan Scan",
      :authors => ["jcran"],
      :description => "This task runs a masscan scan on the target host or domain.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["IpAddress","NetBlock"],
      :example_entities => [{"type" => "NetBlock", "details" => {"name" => "10.0.0.0/24"}}],
      :allowed_options => [
        {:name => "tcp_ports", :regex => "numeric_list", :default => "21,80,443,8000,8009,8080,8081,8443" },
        {:name => "udp_ports", :regex => "numeric_list", :default => "161,500,1900" },
        {:name => "send_rate", :regex => "integer", :default => 100000 },
      ],
      :created_types => [ "DnsRecord","IpAddress", "NetworkService", "Uri" ],
      :queue => "task_scan"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get range, or host
    to_scan = _get_entity_name
    opt_tcp_ports = _get_option("tcp_ports")
    opt_udp_ports = _get_option("udp_ports")
    opt_send_rate = _get_option("send_rate")

    begin

      # Create a tempfile to store result
      temp_file = Tempfile.new("masscan-#{rand(10000000)}")

      port_string = ""
      port_string << "#{opt_tcp_ports}" if opt_tcp_ports.length > 0
      port_string << "," if (opt_tcp_ports.length > 0 && opt_udp_ports.length > 0)
      port_string << "#{opt_udp_ports.split(",").map{|p| "U:#{p}" }.join(",")}" if opt_udp_ports.length > 0

      # shell out to masscan and run the scan
      # TODO - move this to scanner mixin
      masscan_string = "masscan --ports #{port_string} --rate #{opt_send_rate} -oL #{temp_file.path} --range #{to_scan}"
      masscan_string = "sudo #{masscan_string}" unless Process.uid == 0

      _log "Running... #{masscan_string}"
      _unsafe_system(masscan_string)

      f = File.open(temp_file.path).each_line do |line|

        # Skip comments
        next if line =~ /^#.*/
        next if line.nil?

        # PARSE
        state = line.delete("\n").strip.split(" ")[0]
        protocol = line.delete("\n").strip.split(" ")[1]
        port = line.delete("\n").strip.split(" ")[2].to_i
        ip_address = line.delete("\n").strip.split(" ")[3]

        # Get the discovered host (one per line) & create an ip address
        created_entity = _create_entity("IpAddress", { 
          "name" => ip_address, 
          "scoped" => true,
          "whois_full_text" => _get_entity_detail("whois_full_text")
        })

        # this will also add teh the port to the ip address
        _create_network_service_entity(created_entity,
          port, protocol, { 
            "scoped" => true,
            "extended_masscan" => masscan_string 
        })

      end

    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def check_external_dependencies
    # Check to see if masscan is in the path, and raise an error if not
    return false unless _unsafe_system("masscan") =~ /^usage/
  true
  end

end
end
end
