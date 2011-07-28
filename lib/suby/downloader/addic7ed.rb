module Suby
  class Downloader::Addic7ed < Downloader
    Downloader.add(self)

    SITE = 'www.addic7ed.com'
    FORMAT = :file
    LANG_IDS = {
      en: 1,
      es: 5,
      fr: 8
    }
    FILTER_IGNORED = "Couldn't find any subs with the specified language. " +
                     "Filter ignored"

    def subtitles_url
      "/serie/#{CGI.escape show}/#{season}/#{episode}/#{LANG_IDS[lang]}"
    end

    def subtitles_response
      response = http.get(subtitles_url)
      unless Net::HTTPSuccess === response
        raise NotFoundError, "show/season/episode not found"
      end
      response
    end

    def subtitles_body
      body = subtitles_response.body
      if body.include? FILTER_IGNORED
        raise NotFoundError, "no subtitle available"
      end
      body
    end

    def redirected_url download_url
      header = { 'Referer' => "http://#{SITE}#{subtitles_url}" }
      location = get_redirection download_url, header # They check Referer
      if location == '/downloadexceeded.php'
        raise NotFoundError, "download exceeded"
      end
      URI.escape location
    end

    def download_url
      download_url = Nokogiri(subtitles_body).css('a').find { |a|
        a[:href].start_with? '/original/' or
        a[:href].start_with? '/updated/'
      }[:href]

      redirected_url download_url
    end
  end
end
