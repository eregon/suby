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
      next if SUB_EXTENSIONS.include? File.extname(file)
      next puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
        File.exist? File.basename(file, File.extname(file)) + ".#{ext}" }

      begin
        success = Downloader::DOWNLOADERS.find do |downloader|
          begin
            downloader.new(file, options[:lang]).download
          rescue Suby::NotFoundError => error
            puts "#{downloader} did not find subtitles for #{file}" +
                 " (#{error.message})"
            false
          rescue Suby::DownloaderError => error
            puts "#{downloader} had a problem finding subtitles for #{file}" +
                 " (#{error.message})"
            false
          else
            puts "#{downloader} found subtitles for #{file}"
            true
          end
        end
        unless success
          STDERR.puts "No downloader could find subtitles for #{file}"
        end
      rescue
        puts "  The download of the subtitles failed for #{file}:"
        puts "  #{$!.class}: #{$!.message}"
        puts $!.backtrace.map { |line| line.prepend ' '*4 }
      end
    }
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
