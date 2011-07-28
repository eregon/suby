module Suby
  class Downloader::Addic7ed < Downloader
    SITE = 'www.addic7ed.com'
    FORMAT = :file
    LANG_IDS = {
      en: 1,
      es: 5,
      fr: 8
    }
    FILTER_IGNORED = "Couldn't find any subs with the specified language. Filter ignored"

    def download_url
      subtitles_url = "/serie/#{CGI.escape show}/#{season}/#{episode}/#{LANG_IDS[lang]}"
      response = http.get(subtitles_url)
      raise NotFoundError, "show/season/episode not found" unless Net::HTTPSuccess === response
      body = response.body
      raise NotFoundError, "no subtitle available" if body.include? FILTER_IGNORED
      download_url = Nokogiri(body).css('a').find { |a|
        a[:href].start_with? '/original/' or
        a[:href].start_with? '/updated/'
      }[:href]
      location = get_redirection download_url, 'Referer' => "http://#{SITE}#{subtitles_url}" # They check Referer
      raise NotFoundError, "download exceeded" if location == '/downloadexceeded.php'
      URI.escape location
    end
  end
end
