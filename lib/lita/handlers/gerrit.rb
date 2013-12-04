require "lita"

module Lita
  module Handlers
    class Gerrit < Handler

      def self.default_config(config)
        config.url = nil
      end

      # Display link to Gerrit patchset easily
      route /gerrit\s+(\d+)/, :gerrit_url, help: { "gerrit <patchset #>" => "Displays link to gerrit patchset" }

      # Simply concatenate config.url with 'id' from route regex
      def gerrit_url(response)
        if Lita.config.handlers.gerrit.url
          gerrit_url = Lita.config.handlers.gerrit.url.chomp("/")
        else
          raise "Gerrit URL must be defined ('config.handlers.gerrit.url')"
        end

        patchset_id = response.matches.flatten.first
        patchset_url = "#{gerrit_url}/#{patchset_id}"

        response.reply("Review #{patchset_id} is at #{patchset_url}")
      rescue Exception => e
        response.reply("Error: #{e.message}")
      end
    end

    Lita.register_handler(Gerrit)
  end
end
