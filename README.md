# Georgia Recipes

Capistrano recipes for Georgia CMS. Helps you setup a VM with the necessary dependencies to run a full Rails stack with Georgia CMS

## Installation

Add this line to your application's Gemfile:

    gem 'georgia_recipes', group: :development

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install georgia_recipes

## Usage

Drop this line of code in your `config/deploy.rb` file to include additional recipes.

    require 'georgia_recipes/all'

Or require them individually:

``` ruby
require 'georgia_recipes/base'
require 'georgia_recipes/chef'
require 'georgia_recipes/elasticsearch'
require 'georgia_recipes/memcached'
require 'georgia_recipes/mongodb'
require 'georgia_recipes/nginx'
require 'georgia_recipes/unicorn'
require 'georgia_recipes/rbenv'
require 'georgia_recipes/redis'
require 'georgia_recipes/solr'
require 'georgia_recipes/postgresql'
...
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/georgia_recipes/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
