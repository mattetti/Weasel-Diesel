# WeaselDiesel Changelog

All changes can be seen on GitHub and git tags are used to isolate each
release.

## HEAD
* Remove deprecated #controller_dispatch.

## 1.3.0
* Move documentation generation from wd_sinatra into Weasel-Diesel.
* Drop support for Ruby 1.8.7.
* Fix rspec deprecation: `expect { }.not_to raise_error(SpecificErrorClass)`
* DSL now only extends the top level main object.

## 1.2.2:
* Added support for anonymous top level arrays.

## 1.2.1:

* Modified the way an empty string param is cast/verified. If a param is
passed as an empty string but the param isn't specified as a string, the
param is nullified. So if you pass `{'id' => ''}`, and `id` is set to be
an integer param, the cast params will look like that: `{'id' => nil}`,
however if `name` is a string param and `{'name' => ''}` is passed, the
value won't be nullified.

## 1.2.0:

* All service urls are now stored with a prepended slash (if not defined
  with one). `WDList.find(<verb>, <url>)` will automatically find the
right url even if the passed url doesn't start by a '/'. This should be
backward compatible with most code out there as long as your code
doesn't do a direct lookup on the url.
The reason for this change is that I think I made a design mistake when
I decided to define urls without a leading '/'. Sinatra and many other
frameworks use that leading slash and it makes sense to do the same.

* Adding a duplicate service (same url and verb) now raises an exception
  instead of silently ignoring the duplicate.

* Upgraded test suite to properly use `WDList.find`.
