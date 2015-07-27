# cmless

[![Gem Version](https://badge.fury.io/rb/cmless.svg)](http://badge.fury.io/rb/cmless)
[![Build Status](https://travis-ci.org/WGBH/cmless.svg)](https://travis-ci.org/WGBH/cmless)

Alternative to full CMS, inspired by Jekyll: Rather than maintaining a database,
and worrying about your own WYSIWYG editor, keep site content under version control,
use github's editor+preview on the markdown, and this gem provides model classes
for access to the data. 

## Usage

The test suite is the best place to look for examples right now.
The basic idea is that you subclass `Cmless`, filling in a few blanks:

- Location of the markdown files is specified via a constant:
```
ROOT = File.expand_path('../your/relative/path', File.dirname(__FILE__))
```
- Sections you want to extract are identified with `attr_read`s:
```
attr_reader :summary_html
atty_reader :reviews_html
```
- There are three special html accessors:
  - `#head_html` will get whatever lies between the h1 at the top, and the first h2.
  - `#body_html` will grab the rest of the document, h2s and all.
  - `#title_html` will grab the first h1.

When all this is done you can pull back instances populated with data from the Markdown.
Besides the accessors, you can also call
  - `#ancestors`
  - `#children`
  - `#path`

These *class* methods are also available:
  - `#find_by_path`
  - `#all`
  - `#each` and everything else that comes with `Enumerable`.

## Example

Let's assume you have a rails app, and will use Cmless for the "collection" pages.

In `config/routes.rb`:
```ruby
# Only needed if you want a hierarchical collection.
# If it's flat, you could just use the Rails id convention.
allow_slashes = lambda { |req|
  path = req.params['path']
  path.match(/^[a-z0-9\/-]+$/) && !path.match(/^rails/)
}

get '/collections', to: 'collections#index'
get '/collections/*path', to: 'collections#show', constraints: allow_slashes
```

In `app/models/collection.rb`:
```ruby
class Collection < Cmless
  ROOT = File.expand_path('../views/collections', File.dirname(__FILE__))
  attr_reader :body_html
end
```

In `app/controllers/collections_controller.rb`:
```ruby
class CollectionsController
  def index
    @collections = Collection.all
  end
  def show
    @collection = Collection.find_by_path(path)
  end
end
```

## Development

- Make your changes.
- Run tests: `rspec`
- Clean up formatting: `rubocop --auto-correct`
- When it works, increment the version number.
- Push changes to Github

To publish gem:
- Create a rubygems account and get your credentials, if you haven't already: 
```
curl -u my-user-name https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials
chmod 0600 ~/.gem/credentials
```
- Create gem: `gem build cmless.gemspec`
- Push gem: `gem push cmless-X.Y.Z.gem`
