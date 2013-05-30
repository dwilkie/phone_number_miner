# encoding: utf-8

module PhoneNumberMiner
  require 'mechanize'

  class AngkorThom

    # Gets data from the following catalogue pages
    # http://akt-media.com/friendship.php?f=2
    # http://akt-media.com/friendship.php?f=3

    BASE_URL = "http://akt-media.com/friendship.php?f="
    COUNTRY_ID = "855"
    ANGKOR_THOM_CATALOGUE_ID = 2
    DARA_CATALOGUE_ID = 3

    def mine!(angkor_thom_page = nil, dara_page = nil)
      phone_numbers = []
      catalogues(angkor_thom_page, dara_page).each do |catalogue_id, start_page|
        catalogue = visit_catalogue(catalogue_id)
        page_range(start_page).each do |potential_page|
          if page_link = link_to_page(catalogue, potential_page)
            page_link.click
            agent.page.search("#left_layout table li p").first.children.each do |child|
              if child.text =~ /(\d+\-?\d+)/
                formatted_number = $~[1].gsub("-", "")
                formatted_number.slice!(0)
                phone_numbers << COUNTRY_ID + formatted_number
              end
            end
          end
        end
      end
      phone_numbers.uniq
    end

    private

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
