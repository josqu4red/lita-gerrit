require "spec_helper"

describe Lita::Handlers::Gerrit, lita_handler: true do
  it { routes("get me gerrit 123, please").to(:change_details) }
  it { doesnt_route("gerrit foo").to(:change_details) }

  it { routes_http(:post, "/gerrit/hooks").to(:hook) }
end
