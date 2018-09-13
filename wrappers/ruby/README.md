Planga Ruby Wrapper:
====================

**requirements:**

* Ruby >= 2.4.1
* gem

**Build and Deploy new gem:**

* run `gem build planga.gemspec`
* run `gem push planga-n.n.n.gem`

**Installing the new gem:**

* run `gem install planga`

**Example usage**

```ruby
require 'planga'

conf = PlangaConfiguration.new("foobar", "kl9psH9VrLZ1hfsPY0b3-W", "general", "1234", "Bob", "my_container_div")

snippet = Planga.get_planga_snippet(conf)
```