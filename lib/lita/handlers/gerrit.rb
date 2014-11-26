module Lita
  module Handlers
    class Gerrit < Handler

      config :url, default: "https://gerrit.example.com"
      config :username, default: "foo"
      config :password, default: "bar"
      config :default_room

      #
      # Fetch details of a given patchset
      #

      route /gerrit\s+(\d+)/, :change_details, help: { "gerrit <change #>" => "Displays details of a gerrit change" }

      def change_details(response)
        change_id = response.matches.flatten.first
        change_uri = "#{config.url.chomp("/")}/a/changes/#{change_id}"
        change_link = "#{config.url.chomp("/")}/#{change_id}"

        http_resp = HTTParty.get(change_uri, :digest_auth => {
          username: config.username,
          password: config.password
        })

        case http_resp.code
        when 200
          change = MultiJson.load(http_resp.body.lines.to_a[1..-1].join)
          message = "[gerrit] [#{change["project"]}] \"#{change["subject"]}\" by #{change["owner"]["name"]}. #{change_link}"
        when 404
          message = "[gerrit] Change ##{change_id} does not exist"
        else
          raise "Failed to fetch #{change_uri} (#{http_resp.code})"
        end

        response.reply(message)
      rescue Exception => e
        response.reply("[gerrit] Error: #{e.message}")
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
        elsif config.default_room
          room = config.default_room
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

      #
      # Notification from Jenkins build
      #

      http.post "/gerrit/build/:room", :build_notification

      def build_notification(request, response)
        target = Source.new(room: request.env["router.params"][:room])
        notification = MultiJson.load(request.body.read)
        build = notification["build"]
        params = build["parameters"]

        message = "[jenkins] [#{params["GERRIT_PROJECT"]}] Build %s for \"#{params["GERRIT_CHANGE_SUBJECT"]}\" by #{params["GERRIT_PATCHSET_UPLOADER_NAME"]}"

        if build["phase"] == "FINALIZED"
          case build["status"]
          when "FAILURE"
            message = message % "FAILED"
            message += " (#{build["full_url"]})"
          when "SUCCESS"
            message = message % "OK"
          else
            message = message % "UNKNOWN"
          end

          robot.send_message(target, message)
        end

      rescue Exception => e
        robot.send_message(target, "[jenkins] failed to process Gerrit build event (#{e.message})")
      end

      private

      # List of supported hooks
      # (https://gerrit-review.googlesource.com/Documentation/config-hooks.html#_supported_hooks)

      def patchset_created(params)
        message = "[gerrit] [%s] %s uploaded patchset %s. %s"
        message % [params["project"], params["uploader"], params["patchset"], params["change-url"]]
      end

      def comment_added(params)
        message = "[gerrit] [%s]: %s commented %s (V:%s/CR:%s)"
        message % [params["project"], params["author"], params["change-url"], params["verified"], params["reviewed"]]
      end

      def change_merged(params)
        message = "[gerrit] [%s] %s merged %s"
        message % [params["project"], params["submitter"], params["change-url"]]
      end
    end

    Lita.register_handler(Gerrit)
  end
end
