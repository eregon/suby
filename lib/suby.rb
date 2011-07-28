require_relative 'suby/downloader_error'
require_relative 'suby/not_found_error'
require_relative 'suby/downloader'
require 'zip/zip'

module Suby
  extend self

  SUB_EXTENSIONS = %w[srt sub]
  TEMP_ARCHIVE_NAME = '__archive__'

  def download_subtitles(files, options = {})
    files.each { |file|
      next puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
        File.exist? File.basename(file, File.extname(file)) + ".#{ext}"
      }
      download_subtitles_for_file(file, options)
    }
  end

  def download_subtitles_for_file(file, options)
    begin
      success = Downloader::DOWNLOADERS.find { |downloader_class|
        try_downloader(downloader_class.new(file, options[:lang]))
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
      downloader.download
    rescue Suby::NotFoundError => error
      puts "#{downloader.class} did not find subtitles for " +
           "#{downloader.file} (#{error.message})"
      false
    rescue Suby::DownloaderError => error
      puts "#{downloader.class} had a problem finding subtitles for " +
           "#{downloader.file} (#{error.message})"
      false
    else
      puts "#{downloader.class} found subtitles for #{downloader.file}"
      true
    end
  end

  def extract_sub_from_archive(archive, format, basename)
    case format
    when :zip
      Zip::ZipFile.open(archive) { |zip|
        sub = zip.entries.find { |entry|
          entry.to_s =~ /\.(?:#{SUB_EXTENSIONS.join '|'})$/
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
