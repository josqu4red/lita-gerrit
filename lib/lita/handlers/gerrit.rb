require "lita"

module Lita
  module Handlers
    class Gerrit < Handler
    end

    Lita.register_handler(Gerrit)
  end
end
