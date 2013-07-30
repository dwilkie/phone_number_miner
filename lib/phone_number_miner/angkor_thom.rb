# encoding: utf-8

module PhoneNumberMiner
  require 'mechanize'

  class AngkorThom
    require 'google/transliterate'

    # Gets data from the following catalogue pages
    # http://akt-media.com/friendship.php?f=2
    # http://akt-media.com/friendship.php?f=3

    BASE_URL = "http://akt-media.com/friendship.php?f="
    COUNTRY_ID = "855"

    CATALOGUES = {
      :angkor_thom => 2,
      :dara => 3
    }

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
      phone_number_catalogues = catalogues(angkor_thom_page, dara_page)
      @latest_catalogue_pages = {}
      phone_number_catalogues.each do |catalogue_id, start_page|
        catalogue = visit_catalogue(catalogue_id)
        page_range(start_page).each do |potential_page|
          if page_link = link_to_page(catalogue, potential_page)
            @latest_catalogue_pages[catalogue_id] = potential_page
            page_link.click
            page_data(agent.page).each do |child|
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

    def latest_angkor_thom_page
      latest_catalogue_page(:angkor_thom)
    end

    def latest_dara_page
      latest_catalogue_page(:dara)
    end

    private

    def latest_catalogue_page(catalogue)
      latest_page = latest_catalogue_pages[CATALOGUES[catalogue]]
      latest_page.to_i if latest_page
    end

    def page_data(page)
      data_page = page.search("#left_layout table li p").first
      data_page ? data_page.children : []
    end

    def latest_catalogue_pages
      @latest_catalogue_pages ||= {}
    end

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
      Google::Transliterate::Transliterator.new.transliterate!(
        "kh", metadata[1].strip
      ).gsub(/\s+/, "").encode(
        'ASCII', :invalid => :replace, :undef => :replace, :replace => ''
      ) if metadata[1]
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
        CATALOGUES[:angkor_thom] => angkor_thom_page.to_i + 1,
        CATALOGUES[:dara] => dara_page.to_i + 1
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
