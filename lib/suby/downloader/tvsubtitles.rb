module Suby
  class Downloader::TVSubtitles < Downloader
    SITE = 'www.tvsubtitles.net'
    SEARCH_URL = '/search.php'

    # cache
    SHOW_URLS = {}
    SHOW_PAGES = {}

    def show_url
      SHOW_URLS[show] ||= begin
        post = Net::HTTP::Post.new(SEARCH_URL)
        post.form_data = { 'q' => show }
        results = Nokogiri http.request(post).body
        url = results.css('ul li div a').first[:href]

        raise 'could not find the show' unless /^\/tvshow-(\d+)\.html$/ =~ url
        "/tvshow-#{$1}-#{season}.html"
      end
    end

    def episode_url
      @episode_url ||= begin
        SHOW_PAGES[show] ||= Nokogiri http.get(show_url).body

        url = nil
        SHOW_PAGES[show].css('div.left_articles table tr').find { |tr|
          tr.children.find { |td| td.name == 'td' && td.text =~ /\A#{season}x0?#{episode}\z/ }
        }.children.find { |td|
          td.children.find { |a|
            a.name == 'a' && a[:href].start_with?('episode') && url = a[:href]
          }
        }
        raise "invalid episode url: #{episode_url}" unless url =~ /^episode-(\d+)\.html$/
        "/episode-#{$1}-#{lang}.html"
      end
    end

    def subtitles_url
      @subtitles_url ||= begin
        subtitles = Nokogiri http.get(episode_url).body

        # TODO: choose 720p or most downloaded instead of first found
        url = subtitles.css('div.left_articles a').find { |a| a.name == 'a' && a[:href].start_with?('/subtitle') }[:href]
        raise 'invalid subtitle url' unless url =~ /^\/subtitle-(\d+)\.html/
        url
      end
    end

    def download_url
      @download_url ||= URI.escape '/' + http.get(subtitles_url.sub('subtitle', 'download'))['Location']
    end
  end
end
