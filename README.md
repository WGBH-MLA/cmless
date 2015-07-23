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

- Location of the markdown files is specified via a class method:
```
def self.root_path
  File.expand_path('../your/relative/path', File.dirname(__FILE__))
end
```
- Sections you want to extract are identified with `attr_read`s:
```
attr_reader :summary_html
atty_reader :reviews_html
```
- There are two special html accessors:
  - `head_html` will get whatever lies between the h1 at the top, and the first h2.
  - `body_html` will grab the rest of the document, h2s and all.

When all this is done you can pull back instances populated with data from the Markdown.
Besides the accessors, you can also call
  - `#title`
  - `#ancestors`
  - `#children` 


## Development

- Make your changes.
- Run tests: `rspec`
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
