# lita-gerrit

**lita-gerrit** is a handler for [Lita](https://github.com/jimmycuadra/lita) that allows interaction with Gerrit code review tool.

It listens for patchset ids on the chat and for events on HTTP interface.

## Installation

Add lita-gerrit to your Lita instance's Gemfile:

```ruby
gem "lita-gerrit"
```

## Configuration

* `url` (String) - "sprintf" URL pattern of your Gerrit instance, with one `%s` which will be substituted with patchset id.

### Example

```ruby
Lita.configure do |config|
  config.handlers.gerrit.url = "https://gerrit.example.com/%s"
end
```

## Usage

### Chat functions

```
lita > gerrit 42
Review 42 is at https://gerrit.example.com/42

```
(see above config)

### HTTP endpoints

lita-gerrit listens for events triggered by Gerrit hooks. An example hook is provided in [contrib](https://github.com/josqu4red/lita-gerrit/tree/master/contrib) directory.

Currently only these hooks are implemented:
 * patchset_created
 * comment_added
 * change_merged

See whole list of hooks in [Gerrit doc](https://gerrit-review.googlesource.com/Documentation/config-hooks.html)

## License

[MIT](http://opensource.org/licenses/MIT)
