# WeaselDiesel Changelog

All changes can be seen on GitHub and git tags are used to isolate each
release.

**1.2.0**: 

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
