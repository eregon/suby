require_relative 'suby/downloader_error'
require_relative 'suby/not_found_error'
require_relative 'suby/filename_parser'
require_relative 'suby/downloader'

require 'term/ansicolor'
gem 'rubyzip2'
require 'zip'

module Suby
  extend self

  SUB_EXTENSIONS = %w[srt sub]
  TEMP_ARCHIVE_NAME = '__archive__'

  def download_subtitles(files, options = {})
    files.each { |file|
      next unless File.file? file
      next puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
        File.exist? File.basename(file, File.extname(file)) + ".#{ext}"
      }
      download_subtitles_for_file(file, options)
    }
  end

  def download_subtitles_for_file(file, options)
    begin
      show, season, episode = FilenameParser.parse(file)
      puts file
      success = Downloader::DOWNLOADERS.find { |downloader_class|
        try_downloader(downloader_class.new(file, show, season, episode, options[:lang]))
      }
      unless success
        STDERR.puts "No downloader could find subtitles for #{file}"
      end
    rescue
      puts "  The download of the subtitles failed for #{file}:"
      puts "  #{$!.class}: #{$!.message}"
      puts $!.backtrace.map { |line| line.prepend ' '*4 }
    end
  end

  def try_downloader(downloader)
    begin
      print "  #{downloader.to_s.ljust(20)}"
      downloader.download
    rescue Suby::NotFoundError => error
      puts Term::ANSIColor.blue "Failed: #{error.message}"
      false
    rescue Suby::DownloaderError => error
      puts Term::ANSIColor.red "Error: #{error.message}"
      false
    else
      puts Term::ANSIColor.green "Found"
      true
    end
  end

  def extract_sub_from_archive(archive, format, basename)
    case format
    when :zip
      Zip::ZipFile.open(archive) { |zip|
        sub = zip.entries.find { |entry|
          entry.to_s =~ /\.#{Regexp.union SUB_EXTENSIONS}$/
        }
        raise "no subtitles in #{archive}" unless sub
        name = basename + File.extname(sub.to_s)
        sub.extract(name)
      }
    else
      raise "unknown archive type (#{archive})"
    end
  ensure
    # Cleaning
    File.unlink archive if File.exist? archive
  end
end
