# InfinityQ
This is a ruby irc bot. He's the successor to all previous p*q versions.
## Overview
infinityq is a bot that revolves around extensions. He's constructed using a basic eventing system and a little bit
of threading (one thread per server connection).

The areas worth mentioning are:

*  Dynamic Protocol parsing
*  Channel and User database
*  Extensions and Syntax
*  Configuration file
*  Documentation
*  Tests
*  Code coverage
*  Bundler use

### Dynamic Protocol Parsing
This bot is a bit unique in that it doesn't know about the protocol until runtime. The irc.proto file uses a syntax
to declare IRC protocol events. If no event is configured for the IRC message it will simply fallback to raw. All messages
go through the raw event anyways, even a normal event is found for it.

The syntax is straightforward:

```
#target <= This may be a channel or a user.
:msg <= This eats the current argument plus all remaining ones.
[option] <= This argument may or may not be present (must come at end).
*list <= This argument should be parsed as a comma seperated list.
```

The first argument in the line is the name of the event, if this is numeric, in the bot it will be referred to as
e + numeric (for example a 411 event will be e411 inside the bot, this is to ensure symbol usage is allowed as 411 is
not a valid symbol).

### Channel and User database
There's a rudimentary channel and user database. It doesn't flush until the bot closes this is something that should
be addressed. It keeps track of channels, users, and permissions. There's also storage mechanisms so an extension
can store data against a user or channel arbitrarily.

### Extensions and Syntax
Extensions were given some nice syntax to create them fast and easily. People don't need to be concerned
about the details of events just how you can use them easily. I'll take some excerpts from Test_2.rb to show
how the extensions work.

```ruby
class Test_2 < Extension
 def ext_load
    function :both, :private, :add_su, 'super_me'
    event :invite, :inv
  end
end
```

The ext_load function is where an extension should register all of its events. Of course you can register and
unregister on the fly but it's good to have a standard.

The event method should be straightforward, registers the function 'inv' to the event 'invite' so it will be called
whenever the invite event is fired (see above for how to know the names of events).

The function method is much more complicated and powerful. The first argument sets the type of message (privmsg/notice/both)
and the second argument sets it's publicity (public/private/both - where public is in a channel, and private is directly
to the bot. The third argument is a callback function (for you to handle the event), the fourth argument is a trigger
that in public must be prefixed by the bot's extension prefix (see configuration file). And a fifth and optional parameter
is the access required which can look like this (with the exception that any_of and all_of should be mutually exclusive).

```ruby
{ access: 50, any_of: 'abc', all_of: 'dez' }
```

This makes it easy to interact with the user and channel database as the function itself will take care of permission
checks on the command.

Extensions also have the ability to access a miscellaneous data store using the db function.

__Note__: In IRC there's this issue in bots where we don't know the users hostname and can't resolve him to a user
we know about. There's special functionality for extensions called fetch_user that uses a whois request and a handler
to effectively delay the event until the user is looked up. See Test_2 for an example.

### Configuration file
The configuration file is pretty simple. It uses yaml. Most entries are symbols so prefix them with :. The values
propagate down unless you specify a value specifically for a given server. That is, every server you create gets all
the values defined globally copied into them, you can override any of those values by defining it again inside the server.
This means that two different servers could even be using seperate protocol files!

### Documentation
Everything has been documented using YARD. I don't bundle it here so simply run yard doc to generate full documentation
for this project.

### Tests
There is a full rspec test suite with very high code coverage for this bot. It uses some expensive mocks because it was
fun for me too. That's not necessarily a good thing.

To run the tests either use guard with the provided guard file (just run guard) or use rspec spec/. The spec helper is
used to generate code coverage statistics so don't use that.

The tests have two flavors, a watered down version, and the full blown version. The reason for this is the networking and
file system requirements. Set the environment variable INF_ENV="TEST" to run the tests without touching the filesystem
or network. Leave that off to actually have it connect to the configured server and run the tests (caution very many
connections to the server are made and you might get banned for it!) There are hardcoded files to avoid some of the reqs
so you'll be able to find awkward copies of the config lying around in the test code.

### Code coverage
SimpleCov is used to generate code coverage statistics. Simply run rspec spec/spec_helper.rb spec/ to run the tests
with code coverage enabled.
