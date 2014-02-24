require "spec_helper"

describe Lita::Handlers::Gerrit, lita_handler: true do
  it { routes("get me gerrit 123, please").to(:gerrit_url) }
  it { doesnt_route("gerrit foo").to(:gerrit_url) }

  it { routes_http(:post, "/lita/gerrit").to(:receive) }
end
