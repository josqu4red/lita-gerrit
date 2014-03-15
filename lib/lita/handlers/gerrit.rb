require "lita"

module Lita
  module Handlers
    class Gerrit < Handler

      def self.default_config(config)
        config.url = "https://gerrit.example.com/%s"
        config.default_room = nil
      end

      # Display link to Gerrit patchset easily
      route /gerrit\s+(\d+)/, :gerrit_url, help: { "gerrit <patchset #>" => "Displays link to gerrit patchset" }

      # Simply concatenate config.url with 'id' from route regex
      def gerrit_url(response)
        patchset_id = response.matches.flatten.first
        patchset_url = Lita.config.handlers.gerrit.url % patchset_id

        response.reply("Review #{patchset_id} is at #{patchset_url}")
      rescue Exception => e
        response.reply("Error: #{e.message}")
      end

      # Notify the creation/comment/merge/etc. of a Gerrit patchset
      http.post "/lita/gerrit", :receive

      def receive(request, response)
        if request.params.has_key?("action")
          action = request.params["action"].gsub("-", "_").to_sym

          unless respond_to?(action, true)
            raise "Action #{action} is not supported by Gerrit handler"
          end
        else
          raise "Action must be defined in hook's parameters"
        end

        if request.params.has_key?("room")
          room = request.params["room"]
        elsif Lita.config.handlers.gerrit.default_room
          room = Lita.config.handlers.gerrit.default_room
        else
          raise "Room must be defined. Either fix your hook or specify a default room ('config.handlers.gerrit.default_room')"
        end

        # build message from action and params
        message = send(action, request.params)
        target = Source.new(room: room)

        robot.send_message(target, message)
      rescue Exception => e
        Lita.logger.error(e.message)
      end

      private

      # List of supported hooks
      # (https://gerrit-documentation.storage.googleapis.com/Documentation/2.7/config-hooks.html#_supported_hooks)

      def patchset_created(params)
        message = "gerrit: patchset %s has been uploaded by %s for project %s. Review is at %s"
        message % [params["patchset"], params["uploader"], params["project"], params["changeurl"]]
      end

      def comment_added(params)
        message = "gerrit(%s): %s commented %s (V:%s/CR:%s)"
        message % [params["project"], params["author"], params["changeurl"], params["verified"], params["reviewed"]]
      end

      def change_merged(params)
        message = "gerrit: Merge of #{changeurl} by #{submitter} for project #{project}"
        message % [params["changeurl"], params["submitted"], params["project"]]
      end
    end

    Lita.register_handler(Gerrit)
  end
end
