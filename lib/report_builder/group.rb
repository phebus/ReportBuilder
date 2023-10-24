module ReportBuilder
  require_relative 'feature'

  class Group < OpenStruct
    def initialize(name:, files:)
      super

      self.name     = name
      self.features = process_features(delete_field(:files))
    end

    private

    def process_features(files)
      features = files.map do |file|
        data = File.read(file)
        begin
          JSON.parse(data, object_class: Feature)
        rescue StandardError
          puts 'Warning:: Invalid Input File ' + file
          puts 'JSON Error:: ' + $!.to_s
          next
        end
      end.flatten

      features.sort_by!(&:name)
      features.each(&:normalize_elements)
    end
  end
end
