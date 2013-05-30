# PhoneNumberMiner

[![Build Status](https://travis-ci.org/dwilkie/phone_number_miner.png)](https://travis-ci.org/dwilkie/phone_number_miner)

Mines real people's phone numbers which are publicly available on the Internet. This is an example only. Please don't use it to spam people.

## Installation

Add this line to your application's Gemfile:

    gem 'phone_number_miner'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install phone_number_miner

## Usage

Here's an example of mining phone numbers from [Angkor Thom Media](http://akt-media.com/friendship.php?f=2)

    require 'phone_number_miner'

    angkor_thom = PhoneNumberMiner::AngkorThom.new
    puts angkor_thom.mine!.count

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
