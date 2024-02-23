require 'json'

class MasterJsonBuilder
  class MissingBragsError < StandardError; end
  attr_reader :brag_directory_path, :filepaths, :master_json

  def initialize
    @brag_directory_path = 'brags'
    @filepaths = []
    @master_json = {}
  end

  def self.update_master_json
    new.build_json
  end

  def build_json
    files_in_dir
    create_master_json
    output_humble_brag
  end

  private

  def files_in_dir(directory = brag_directory_path)
    Dir.each_child(directory) do |filename|
      full_path = "#{directory}/#{filename}"

      if File.directory?(full_path)
        files_in_dir(full_path)
      else
        filepaths << full_path
      end
    end

    filepaths
  end

  def create_master_json
    raise MissingBragsError.new('Nothing to brag about :(') if filepaths.empty?

    filepaths.each do |file|
      if %r{brags/\d\d\d\d/\d\d/(\d\d\d\d)-(\d\d)-\d\d-\d+.json} =~ file
        file_year = Regexp.last_match(1)
        file_month = Regexp.last_match(2)
        json_key = "#{file_year}-#{file_month}"
        master_json[json_key] = {} unless master_json.key?(json_key)

        append_file_to_json(file, json_key)
      else
        puts "Filestructure does not match expected. Given: #{file}, expected 'brags/yyyy/mm/yyyy-mm-dd-id.json'"
      end
    end
  end

  def append_file_to_json(filename, json_key)
    file_contents = File.read(filename)
    file_hash = JSON.parse(file_contents)

    new_labels = file_hash['labels']
    brag_text = file_hash['text']
    brag_links = file_hash['links']

    new_labels = ['uncategorised'] if new_labels.empty?
    puts "Missing text & links in #{filename}" if brag_text.empty? && brag_links.empty?

    brag_for_label = {
      'text': brag_text,
      'links': brag_links
    }

    new_labels.each do |label|
      if master_json[json_key].key?(label)
        exiting_list = master_json[json_key][label]
        exiting_list << brag_for_label
      else
        master_json[json_key][label] = [brag_for_label]
      end
    end
  end

  def output_humble_brag
    File.open('humble_brags.json', 'w') { |f| f.write master_json.to_json }
  end
end

MasterJsonBuilder.update_master_json
