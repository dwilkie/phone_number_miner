# encoding: utf-8

module PhoneNumberMiner
  require 'mechanize'

  class AngkorThom
    require 'httparty'

    # Gets data from the following catalogue pages
    # http://akt-media.com/friendship.php?f=2
    # http://akt-media.com/friendship.php?f=3

    include HTTParty

    class Parser::Simple < HTTParty::Parser
      require 'csv'

      def parse
        CSV.parse(body.gsub(/(?:\[|\])/, ""))[0][3].gsub(/\s+/, "")
      end
    end

    parser Parser::Simple

    GOOGLE_TRANSLATE_URL = "http://translate.google.com/translate_a/t"
    BASE_URL = "http://akt-media.com/friendship.php?f="
    COUNTRY_ID = "855"
    ANGKOR_THOM_CATALOGUE_ID = 2
    DARA_CATALOGUE_ID = 3
    KHMER_NUMERALS = ["០", "១", "២", "៣", "៤", "៥", "៦", "៧", "៨", "៩"]
    PROVINCE_ABBREVIATIONS = {
      "ប.ជ" => "Banteay Meanchey",
      "ប.ប" => "Battambang",
      "ក.ច" => "Kampong Cham",
      "ក.ឆ" => "Kampong Chhnang",
      "ក.ស្ព" => "Kampong Speu",
      "ក.ធ" => "Kampong Thom",
      "ក.ព" => "Kampot",
      "ក.ណ" => "Kandal",
      "ខ.ក" => "Kep",
      "ក.ក" => "Koh Kong",
      "ក្រ.ច" => "Kratie",
      "ម.រ" => "Mondulkiri",
      "ឧ.ជ" => "Oddar Meanchey",
      "ប.ល" => "Pailin",
      "ភ.ព" => "Phnom Penh",
      "ព្រ.ហ" => "Preah Vihear",
      "ព.វ" => "Prey Veng",
      "ព.ស" => "Pursat",
      "រ.រ" => "Ratanakiri",
      "ស.រ" => "Siem Reap",
      "ស.នុ" => "Kampong Som",
      "ស្ទ.ត" => "Stung Treng",
      "ស្វ.រ" => "Svaay Rieng",
      "ត.ក" => "Takeo"
    }

    def mine!(angkor_thom_page = nil, dara_page = nil)
      phone_numbers = {}
      catalogues(angkor_thom_page, dara_page).each do |catalogue_id, start_page|
        catalogue = visit_catalogue(catalogue_id)
        page_range(start_page).each do |potential_page|
          if page_link = link_to_page(catalogue, potential_page)
            page_link.click
            agent.page.search("#left_layout table li p").first.children.each do |child|
              child_text = child.text
              if child_text =~ /(\d+\-\d+)/
                formatted_number = $~[1].gsub("-", "")
                formatted_number.slice!(0)
                full_number = COUNTRY_ID + formatted_number

                metadata = child_text.split

                phone_numbers[full_number] = {
                  "gender" => gender(metadata),
                  "name" => name(metadata),
                  "age" => age(metadata),
                  "location" => location(metadata)
                }
              end
            end
          end
        end
      end
      phone_numbers
    end

    private

    def location(metadata)
      khmer_location = metadata[3].to_s.strip
      PROVINCE_ABBREVIATIONS.each do |khmer_abbreviation, english_name|
        return english_name if khmer_location =~ /#{khmer_abbreviation}/
      end
      nil
    end

    def age(metadata)
      khmer_age = metadata[2].to_s.strip.dup
      KHMER_NUMERALS.each_with_index do |khmer_numeral, index|
        khmer_age.gsub!(/#{khmer_numeral}/, index.to_s)
      end
      khmer_age.gsub(/\D/, "")
    end

    def name(metadata)
      google_translate(metadata[1].strip) if metadata[1]
    end

    def google_translate(text)
      self.class.get(
        GOOGLE_TRANSLATE_URL,
        :query => {
          :client => "t",
          :sl => "kh",
          :ie => "UTF-8",
          :oe => "UTF-8",
          :q => text
        },
        :headers => {"User-Agent" => "Mozilla/5.0"}
      ).parsed_response
    end

    def gender(metadata)
      khmer_gender = metadata[0].to_s.strip
      if khmer_gender =~ /ខ្ញុំបាទ/
        "m"
      elsif khmer_gender =~ /នាងខ្ញុំ/
        "f"
      end
    end

    def agent
      @agent ||= Mechanize.new
    end

    def catalogues(angkor_thom_page, dara_page)
      {
        ANGKOR_THOM_CATALOGUE_ID => angkor_thom_page.to_i + 1,
        DARA_CATALOGUE_ID => dara_page.to_i + 1
      }
    end

    def page_range(start)
      link_ids = []
      agent.page.links.find_all do |link|
        link_ids << $~[1].to_i if link.text =~ /\-(\d+)/
      end
      start = nil unless start > 1
      (start || link_ids.min)..link_ids.max
    end

    def visit_catalogue(catalogue_id)
      agent.get(BASE_URL + catalogue_id.to_s)
    end

    def link_to_page(catalogue, id)
      catalogue.links.find { |link| link.text =~ /\-#{id}/ }
    end
  end
end