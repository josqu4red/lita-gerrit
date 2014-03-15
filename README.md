# lita-gerrit

**lita-gerrit** is a handler for [Lita](https://github.com/jimmycuadra/lita) that allows interaction with Gerrit code review.

It listens for patchset ids on the chat and for events on HTTP interface.

## Installation

Add lita-gerrit to your Lita instance's Gemfile:

```ruby
gem "lita-gerrit"
```

## Configuration

* `url` (String) - Sprintf URL pattern of your Gerrit instance, with one `%s` which will be substituted with patchset ids.

### Example

```ruby
Lita.configure do |config|
  config.handlers.gerrit.url = "https://gerrit.example.com/%s"
end
```

## Usage

### Chat functions

```
gerrit 4200
```
Will show URL for Gerrit patch 4200 (`https://gerrit.example.com/4200` with the above config)

### HTTP endpoints

lita-gerrit will listen for events triggered by Gerrit hooks. An example hook is provided in [contrib](https://github.com/josqu4red/lita-gerrit/tree/master/contrib) directory.

## License

[MIT](http://opensource.org/licenses/MIT)
