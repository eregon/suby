require_relative 'suby/downloader_error'
require_relative 'suby/not_found_error'
require_relative 'suby/filename_parser'
require_relative 'suby/downloader'
require_relative 'suby/interface'

gem 'rubyzip2'
require 'zip'

module Suby
  SUB_EXTENSIONS = %w[srt sub].map { |ext| ".#{ext}" }
  TEMP_ARCHIVE_NAME = '__archive__'

  class << self
    include Interface

    def download_subtitles(files, options = {})
      files.each { |file|
        next if Dir.exist?(file) or SUB_EXTENSIONS.include?(File.extname(file))
        next puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
          File.exist? File.basename(file, File.extname(file)) + ext
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
        error "\nNo downloader could find subtitles for #{file}" unless success
      rescue
        error "\nThe download of the subtitles failed for #{file}:"
        error "#{$!.class}: #{$!.message}"
        $stderr.puts $!.backtrace
      end
    end

    def try_downloader(downloader)
      begin
        print "  #{downloader.to_s.ljust(20)}"
        downloader.download
      rescue Suby::NotFoundError => error
        failure "Failed: #{error.message}"
        false
      rescue Suby::DownloaderError => error
        error "Error: #{error.message}"
        false
      else
        success "Found"
        true
      end
    end

    def extract_sub_from_archive(archive, format, basename)
      case format
      when :zip
        Zip::ZipFile.open(archive) { |zip|
          sub = zip.entries.find { |entry|
            entry.to_s =~ /#{Regexp.union SUB_EXTENSIONS}$/
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
end
