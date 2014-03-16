require "lita"
require "httparty"

module Lita
  module Handlers
    class Gerrit < Handler
      include HTTParty

      def self.default_config(config)
        config.url = "https://gerrit.example.com"
        config.username = "foo"
        config.password = "bar"
        config.default_room = nil
      end

      #
      # Fetch details of a given patchset
      #

      route /gerrit\s+(\d+)/, :change_details, help: { "gerrit <change #>" => "Displays details of a gerrit change" }

      def change_details(response)
        patchset_id = response.matches.flatten.first
        response.reply(get_change(patchset_id))
      rescue Exception => e
        response.reply("Error: #{e.message}")
      end

      #
      # Notify the creation/comment/merge/etc. of a Gerrit patchset
      #

      http.post "/gerrit/hooks", :hook

      def hook(request, response)
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
      # (https://gerrit-review.googlesource.com/Documentation/config-hooks.html#_supported_hooks)

      def patchset_created(params)
        message = "gerrit: patchset %s has been uploaded by %s in %s. %s"
        message % [params["patchset"], params["uploader"], params["project"], params["change-url"]]
      end

      def comment_added(params)
        message = "gerrit(%s): %s commented %s (V:%s/CR:%s)"
        message % [params["project"], params["author"], params["change-url"], params["verified"], params["reviewed"]]
      end

      def change_merged(params)
        message = "gerrit: Merge of %s by %s in %s"
        message % [params["change-url"], params["submitted"], params["project"]]
      end

      #
      # Helpers
      #

      def get_change(id)
        path = "#{Lita.config.handlers.gerrit.url.chomp("/")}/a/changes/#{id}"
        http_resp = self.class.get(path, :digest_auth => digest_creds)

        case http_resp.code
        when 200
          change = MultiJson.load(http_resp.body.lines.to_a[1..-1].join)
          message = "gerrit: #{change["subject"]} by #{change["owner"]["name"]}"
          message += " in #{change["project"]}. #{gerrit_link(id)}"
        when 404
          message = "Change ##{id} does not exist"
        else
          raise "Failed to fetch #{path} (#{http_resp.code})"
        end
        message
      end

      def digest_creds
        { username: Lita.config.handlers.gerrit.username, password: Lita.config.handlers.gerrit.password }
      end

      def gerrit_link(id)
        "#{Lita.config.handlers.gerrit.url.chomp("/")}/#{id}"
      end
    end

    Lita.register_handler(Gerrit)
  end
end
