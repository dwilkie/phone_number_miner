require 'spec_helper'
require 'phone_number_miner/angkor_thom'

module PhoneNumberMiner
  describe AngkorThom do

    def with_vcr(&block)
      VCR.use_cassette(:angkor_thom) do
        yield
      end
    end

    describe "#mine!(angkor_thom_page = nil, dara_page = nil)" do
      it "should return all numbers with the prefix '855'" do
        results = with_vcr { subject.mine! }
        results.each do |result|
          result.should =~ /^855/
        end
      end

      it "should return only unique numbers" do
        results = with_vcr { subject.mine! }
        results.should == results.uniq
      end

      context "passing no args" do
        it "should get all the numbers from the angkor thom catalogue and the dara catalogue" do
          results = with_vcr { subject.mine! }
          results.size.should == 556 # from VCR cassette
        end
      end

      context "passing an index for the angkor thom catalogue" do
        it "should get phone numbers pages with an id > the given index" do
          results = with_vcr { subject.mine!(423) }
          results.size.should == 431 # from VCR cassette
        end
      end

      context "passings indexes >= than the largest index on the catalogue page" do
        it "should return no results" do
          results = with_vcr { subject.mine!(424, 189) }
          results.size.should == 0
        end
      end
    end
  end
end
