# frozen_string_literal: true

require_relative 'feature'
require_relative 'group'

module ReportBuilder
  class Input
    attr_accessor :input_path

    def initialize(input_path)
      @input_path = input_path
      @groups     = groups
    end

    def groups
      self.input_path = { Main: self.input_path } unless self.input_path.is_a? Hash
      groups          = input_path.map do |name, path|
        files = json_files(path)

        if files.empty?
          puts "Error:: No file(s) found at #{path}"
          next
        end

        group = Group.new(name:, files:)
        group
      end

      groups.each do |group|
        group.features.each do |feature|
          feature.elements.sort_by!(&:line)
        end
      end

      groups
    end

    def json_files(path)
      [path].flatten.map do |file|
        if File.file?(file)
          [file]
        elsif File.exist?(file)
          Dir.glob("#{file}/*.json")
        else
          []
        end
      end.flatten.uniq
    end
  end
end
