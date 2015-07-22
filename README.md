# cmless

[![Gem Version](https://badge.fury.io/rb/cmless.svg)](http://badge.fury.io/rb/cmless)
[![Build Status](https://travis-ci.org/WGBH/cmless.svg)](https://travis-ci.org/WGBH/cmless)

Alternative to full CMS, inspired by Jekyll: Rather than maintaining a database,
and worrying about your own WYSIWYG editor, keep site content under version control,
use github's editor+preview on the markdown, and this gem provides model classes
for access to the data. 

## Library usage

```
$ irb -Ilib -rcmless
> # TODO
```

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
