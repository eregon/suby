require 'net/http'
require 'nokogiri'

module Suby
  extend self

  DEFAULT_OPTIONS = {
    lang: 'en'
  }

  SUB_EXTENSIONS = %w[srt sub]
  TEMP_ARCHIVE_NAME = '__archive__'
  SITE = 'www.tvsubtitles.net'
  SEARCH_URL = '/search.php'

  # cache
  SHOW_URLS = {}
  SHOW_PAGES = {}

  def download_subtitles(file, options = {})
    options = DEFAULT_OPTIONS.merge options
    return if SUB_EXTENSIONS.include? File.extname(file)
    return puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
      File.exist? File.basename(file, File.extname(file)) + ".#{ext}" }

    show, season, episode = parse_filename(file)
    return unless show

    puts "Searching subtitles for #{file}:"
    puts "Show: #{show}, Season: #{season}, Episode: #{episode}"

    Net::HTTP.start(SITE) { |tvsubtitles|
      # search show
      show_url = (SHOW_URLS[show] ||= begin
        post = Net::HTTP::Post.new(SEARCH_URL)
        post.form_data = { 'q' => show }
        results = Nokogiri tvsubtitles.request(post).body
        url = results.css('ul li div a').first[:href]

        raise 'could not find the show' unless /^\/tvshow-(\d+)\.html$/ =~ url
        "/tvshow-#{$1}-#{season}.html"
      end)
      puts "show url: #{show_url}"

      # search episode
      show = (SHOW_PAGES[show] ||= Nokogiri tvsubtitles.get(show_url).body)
      episode_url = nil
      show.css('div.left_articles table tr').find { |tr|
        tr.children.find { |td| td.name == 'td' && td.text =~ /\A#{season}x0?#{episode}\z/ }
      }.children.find { |td|
        td.children.find { |a|
          a.name == 'a' && a[:href].start_with?('episode') && episode_url = a[:href]
        }
      }

      raise "invalid episode url: #{episode_url}" unless episode_url =~ /^episode-(\d+)\.html$/
      episode_url = "/episode-#{$1}-#{options[:lang]}.html"
      puts "episode url: #{episode_url}"

      # subtitles
      subtitles = Nokogiri tvsubtitles.get(episode_url).body

      # TODO: choose 720p or most downloaded instead of first found
      subtitle_url = subtitles.css('div.left_articles a').find { |a| a.name == 'a' && a[:href].start_with?('/subtitle') }[:href]
      raise 'invalid subtitle url' unless subtitle_url =~ /^\/subtitle-(\d+)\.html/
      puts "subtitle url: #{subtitle_url}"

      # download
      download_url = tvsubtitles.get("/download-#{$1}.html")['Location']
      download_url = URI.escape('/'+download_url)
      puts "download url: #{download_url}"

      # extract
      zip = tvsubtitles.get(download_url).body
      open(TEMP_ARCHIVE_NAME, 'wb') { |f| f.write zip }
      subs = extract_subs_from_archive(TEMP_ARCHIVE_NAME)
      new_name = File.basename(file, File.extname(file))+File.extname(subs.first)
      File.rename(subs.first, new_name)
      puts "Renaming to #{new_name}"
    }
  end

  def extract_subs_from_archive(archive)
    case `file #{archive}`
    when /Zip archive data/
      subs = `unzip -qql #{archive}`.scan(/\d{2}:\d{2}   (.+?(?:#{SUB_EXTENSIONS.join '|'}))$/).map(&:first)
      raise "no subtitles in #{archive}" if subs.empty?
      subs_for_unzip = subs.map { |sub| sub.gsub(/(\[|\])/) { "\\#{$1}" } }
      system 'unzip', archive, *subs_for_unzip, 1 => :close
      puts "found subtitles: #{subs.join(', ')}"
    else
      raise "unknown archive type (#{archive})"
    end

    # Cleaning
    File.unlink archive
    subs
  end

  def parse_filename(file)
    if /^(?<show>.+) (?<season>\d{1,2})x(?<episode>\d{1,2}) - .+\.[a-z]+?$/ =~ file
      [show, season.to_i, episode.to_i]
    else
      puts "wrong file format (#{file}). Must be:\n<show> <season>x<episode> - <title>.<ext>"
    end
  end
end
