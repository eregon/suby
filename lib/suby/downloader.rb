require 'net/http'
require 'nokogiri'

module Suby
  class Downloader
    SITE = 'www.tvsubtitles.net'
    SEARCH_URL = '/search.php'

    # cache
    SHOW_URLS = {}
    SHOW_PAGES = {}

    attr_reader :show, :season, :episode, :file, :lang

    def initialize file, lang = 'en'
      @file, @lang = file, lang
      unless /^(?<show>.+) (?<season>\d{1,2})x(?<episode>\d{1,2})(?: - .+)?\.[a-z]+?$/ =~ file
        raise "wrong file format (#{file}). Must be:\n<show> <season>x<episode>[ - <title>].<ext>"
      end
      @show, @season, @episode = show, season.to_i, episode.to_i
    end

    def get_show_url http
      SHOW_URLS[show] ||= begin
        post = Net::HTTP::Post.new(SEARCH_URL)
        post.form_data = { 'q' => show }
        results = Nokogiri http.request(post).body
        url = results.css('ul li div a').first[:href]

        raise 'could not find the show' unless /^\/tvshow-(\d+)\.html$/ =~ url
        "/tvshow-#{$1}-#{season}.html"
      end
    end

    def get_episode_url http, show_url
      show_page = (SHOW_PAGES[show] ||= Nokogiri http.get(show_url).body)

      episode_url = nil
      show_page.css('div.left_articles table tr').find { |tr|
        tr.children.find { |td| td.name == 'td' && td.text =~ /\A#{season}x0?#{episode}\z/ }
      }.children.find { |td|
        td.children.find { |a|
          a.name == 'a' && a[:href].start_with?('episode') && episode_url = a[:href]
        }
      }
      raise "invalid episode url: #{episode_url}" unless episode_url =~ /^episode-(\d+)\.html$/
      "/episode-#{$1}-#{lang}.html"
    end

    def get_subtitles_url http, episode_url
      subtitles = Nokogiri http.get(episode_url).body

      # TODO: choose 720p or most downloaded instead of first found
      subtitle_url = subtitles.css('div.left_articles a').find { |a| a.name == 'a' && a[:href].start_with?('/subtitle') }[:href]
      raise 'invalid subtitle url' unless subtitle_url =~ /^\/subtitle-(\d+)\.html/
      subtitle_url
    end

    def get_download_url http, subtitle_url
      URI.escape '/' + http.get(subtitle_url.sub('subtitle', 'download'))['Location']
    end

    def download
      puts "Searching subtitles for #{file}:"
      puts "Show: #{show}, Season: #{season}, Episode: #{episode}"

      Net::HTTP.start(SITE) { |http|
        show_url = get_show_url http
        puts "show url: #{show_url}"

        episode_url = get_episode_url http, show_url
        puts "episode url: #{episode_url}"

        subtitle_url = get_subtitles_url http, episode_url
        puts "subtitle url: #{subtitle_url}"

        download_url = get_download_url http, subtitle_url
        puts "download url: #{download_url}"

        # extract
        zip = http.get(download_url).body
        open(TEMP_ARCHIVE_NAME, 'wb') { |f| f.write zip }
        subs = Suby.extract_subs_from_archive(TEMP_ARCHIVE_NAME)

        new_name = File.basename(file, File.extname(file))+File.extname(subs.first)
        File.rename subs.first, new_name
        puts "Renaming to #{new_name}"
      }
    end
  end
end
