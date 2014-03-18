# lita-gerrit

[![Build Status](https://travis-ci.org/josqu4red/lita-gerrit.png?branch=master)](https://travis-ci.org/josqu4red/lita-gerrit)
[![Coverage Status](https://coveralls.io/repos/josqu4red/lita-gerrit/badge.png)](https://coveralls.io/r/josqu4red/lita-gerrit)

**lita-gerrit** is a handler for [Lita](https://github.com/jimmycuadra/lita) that allows interaction with Gerrit code review tool.

It allows to fetch Gerrit changes details from the chat and listens for hook events on HTTP interface.

It depends on HTTParty because Gerrit uses HTTP digest authentication, which is not supported by Lita's built-in HTTP client, Faraday.

## Installation

Add lita-gerrit to your Lita instance's Gemfile:

```ruby
gem "lita-gerrit"
```

## Configuration

* `url` (String) - Gerrit service URL
* `username` (String) - Username for REST API
* `password` (String) - Password for REST API

### Example

```ruby
Lita.configure do |config|
  config.handlers.gerrit.url = "https://gerrit.example.com"
  config.handlers.gerrit.username = "foo"
  config.handlers.gerrit.password = "bar"
end
```

## Usage

### Chat functions

```
lita > gerrit 42
gerrit: Display debug informations with correct log level by John Doe in chef. http://gerrit.example.com/42
(gerrit: <commit message> by <author> in <project>. <url>)
```

### HTTP endpoints

lita-gerrit listens for events triggered by Gerrit hooks. An example hook is provided in [contrib](https://github.com/josqu4red/lita-gerrit/tree/master/contrib) directory.

Currently only these hooks are implemented:
 * patchset_created
 * comment_added
 * change_merged

See list of supported hooks in [Gerrit doc](https://gerrit-review.googlesource.com/Documentation/config-hooks.html)

## License

[MIT](http://opensource.org/licenses/MIT)
