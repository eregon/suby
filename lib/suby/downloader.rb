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

    def initialize file, lang = nil
      @file, @lang = file, lang || 'en'
      unless /^(?<show>.+) (?<season>\d{1,2})x(?<episode>\d{1,2})(?: - .+)?\.[a-z]+?$/ =~ file
        raise "wrong file format (#{file}). Must be:\n<show> <season>x<episode>[ - <title>].<ext>"
      end
      @show, @season, @episode = show, season.to_i, episode.to_i
    end

    def http
      @http ||= Net::HTTP.new(SITE).start
    end

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

    def download
      puts "Searching subtitles for #{file}:"
      puts "Show: #{show}, Season: #{season}, Episode: #{episode}"

      puts "show url: #{show_url}"
      puts "episode url: #{episode_url}"
      puts "subtitle url: #{subtitles_url}"
      puts "download url: #{download_url}"

      # extract
      zip = http.get(download_url).body
      http.finish
      open(TEMP_ARCHIVE_NAME, 'wb') { |f| f.write zip }
      subs = Suby.extract_subs_from_archive(TEMP_ARCHIVE_NAME)

      new_name = File.basename(file, File.extname(file))+File.extname(subs.first)
      File.rename subs.first, new_name
      puts "Renaming to #{new_name}"
    end
  end
end
