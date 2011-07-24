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
      subtitles_response = http.get subtitles_url
      raise unless Net::HTTPSuccess === subtitles_response
      download_url = Nokogiri(subtitles_response.body).css('a').find { |a|
        a[:href].start_with? '/original/' or
        a[:href].start_with? '/updated/'
      }[:href]
      request = http.get download_url, 'Referer' => "http://#{SITE}#{subtitles_url}" # They check Referer
      raise "Download exceeded" if request['Location'] == '/downloadexceeded.php'
      URI.escape request['Location']
    end
  end
end
