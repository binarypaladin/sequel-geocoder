Sequel Geocoder
===============

This is a plugin for [Sequel](https://github.com/jeremyevans/sequel/) that
strives to make Sequel models compatible with all the same features available to
[Geocoder](https://github.com/alexreisner/geocoder) ActiveRecord models.

Sequel Geocoder is still in its early stages and some things are subject to
change in the near future---specifically the way initialization works.
Additionally, very little testing has been done thus far so use at your own
risk!

Usage
-----

It's a regular Sequel plugin and as such should work like so:

```ruby
class SomeModel < Sequel::Model
  plugin :geocoder
end
```

Once a model is using the plugin, it should work just like its ActiveRecord
counterpart. See [Geocoder's documentation](https://github.com/alexreisner/geocoder#activerecord)
for details.

Copyright
---------

Copyright (c) 2014 Joshua Hansen. See MIT-LICENSE for further details.
