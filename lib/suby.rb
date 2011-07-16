require_relative 'suby/downloader'

module Suby
  extend self

  SUB_EXTENSIONS = %w[srt sub]
  TEMP_ARCHIVE_NAME = '__archive__'

  def download_subtitles(files, options = {})
    files.each { |file|
      next if SUB_EXTENSIONS.include? File.extname(file)
      next puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
        File.exist? File.basename(file, File.extname(file)) + ".#{ext}" }

      begin
        Downloader::TVSubtitles.new(file, options[:lang]).download
      rescue
        puts "  The download of the subtitles failed for #{file}:"
        puts "  #{$!.class}: #{$!.message}"
        puts $!.backtrace.map { |line| line.prepend ' '*4 }
      end
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
end
