module Suby
  class Downloader::Addic7ed < Downloader
    SITE = 'www.addic7ed.com'
    FORMAT = :file
    LANG_IDS = {
      en: 1,
      fr: 8
    }

    def download_url
      subtitles_url = "/serie/#{CGI.escape show}/#{season}/#{episode}/#{LANG_IDS[lang]}"
      download_url = Nokogiri(get(subtitles_url)).css('a').find { |a|
        a[:href].start_with? '/original/' or
        a[:href].start_with? '/updated/'
      }[:href]
      location = get_redirection download_url, 'Referer' => "http://#{SITE}#{subtitles_url}" # They check Referer
      throw :downloader, "download exceeded" if location == '/downloadexceeded.php'
      URI.escape location
    end
  end
end
