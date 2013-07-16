# encoding: utf-8

require 'spec_helper'
require 'phone_number_miner/angkor_thom'

module PhoneNumberMiner
  describe AngkorThom do
    def with_vcr(options = {}, &block)
      options[:google_translate_cassette] ||= :google_translate
      VCR.use_cassette(:angkor_thom) do
        VCR.use_cassette(options[:google_translate_cassette]) do
          yield
        end
      end
    end

    describe "#mine!(angkor_thom_page = nil, dara_page = nil)" do
      it "should return all numbers with the prefix '855'" do
        results = with_vcr { subject.mine! }
        results.each do |result, metadata|
          result.should =~ /^855/
          metadata.should have_key("gender")
          metadata.should have_key("age")
          metadata.should have_key("name")
          metadata.should have_key("location")
          metadata["name"].should_not =~ /\s+/         # assert all spaces are removed
          metadata["name"].should_not =~ /(?:ị|s̄|ī|r̒)/ # assert non-ASCII characters are removed
          [nil, "m", "f"].should include(metadata["gender"])
        end
      end

      context "passing no args" do
        it "should get all the numbers from the angkor thom catalogue and the dara catalogue" do
          results = with_vcr { subject.mine! }
          results.size.should == 554 # from VCR cassette
        end
      end

      context "passing an index for the angkor thom catalogue" do
        it "should get phone numbers pages with an id > the given index" do
          results = with_vcr(:google_translate_cassette => :google_translate_subset) { subject.mine!(423) }
          results.size.should == 430 # from VCR cassette
        end
      end

      context "passings indexes >= than the largest index on the catalogue page" do
        it "should return no results" do
          results = with_vcr { subject.mine!(424, 189) }
          results.size.should == 0
        end
      end
    end

    describe "#latest_angkor_thom_page" do
      it "should return the lastest angkor thom page index" do
        subject.latest_angkor_thom_page.should == 0
        with_vcr { subject.mine! }
        subject.latest_angkor_thom_page.should == 424 # from VCR cassette
      end
    end

    describe "#latest_dara_page" do
      it "should return the lastest dara page index" do
        subject.latest_dara_page.should == 0
        with_vcr { subject.mine! }
        subject.latest_dara_page.should == 189 # from VCR cassette
      end
    end
  end
end
