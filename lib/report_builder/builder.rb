require 'json'
require 'erb'
require 'pathname'
require 'base64'
require 'ostruct'
require_relative 'input'

module ReportBuilder
  ##
  # ReportBuilder Main class
  #
  class Builder
    attr_accessor :options, :groups

    ##
    # ReportBuilder Main method
    #
    def initialize
      @options           = ReportBuilder.configure
      @input             = Input.new(@options.input_path)
      @groups            = @input.groups
      @json_report_path  = @options.json_report_path || @options.report_path
      @html_report_path  = @options.html_report_path || @options.report_path
      @retry_report_path = @options.retry_report_path || @options.report_path
    end

    # TODO: come up with a better name
    def build_report
      @options.report_types.each do |report_type|
        next unless %i[json html retry].include? report_type

        send("#{report_type}_report")
      end

      [@json_report_path, @html_report_path, @retry_report_path]
    end

    private

    def json_report
      File.write(@json_report_path + '.json', JSON.pretty_generate(process_groups(@groups)))
    end

    def html_report
      if @options.additional_css && File.exist?(@options.additional_css)
        @options.additional_css = File.read(@options.additional_css)
      end

      if @options.additional_js && File.exist?(@options.additional_js)
        @options.additional_js = File.read(@options.additional_js)
      end

      File.write(@html_report_path + '.html', template(@groups.size > 1 ? 'group_report' : 'report').result(binding))
    end

    def retry_report
      File.open(@retry_report_path + '.retry', 'w') do |file|
        @groups.each do |group|
          group.features.each do |feature|
            next unless feature.broken?

            feature.failed_scenarios.each do |scenario|
              file.puts "#{feature.uri}:#{scenario.line}"
            end
          end
        end
      end
    end

    def process_groups(groups)
      return openstruct_to_h(groups.first)[:features] if groups.size == 1

      groups.map do |group|
        openstruct_to_h(group)
      end
    end

    def openstruct_to_h(object)
      object.to_h.transform_values do |value|
        if value.is_a?(OpenStruct)
          openstruct_to_h(value)
        elsif value.is_a?(Array)
          value.map { |v| v.is_a?(String) ? v : openstruct_to_h(v) }
        else
          value
        end
      end
    end

    def template(template)
      @erb           ||= {}
      @erb[template] ||= ERB.new(File.read(File.dirname(__FILE__) + '/../../template/' + template + '.erb'), eoutvar: '_' + template)
    end

    def total_time(data)
      total_time = 0
      data.each { |item| total_time += item.duration }
      total_time
    end

    def duration(milliseconds)
      seconds          = milliseconds.to_f / 1_000_000_000
      minutes, seconds = seconds.divmod(60)

      if minutes > 59
        hours, minutes = minutes.divmod(60)
        "#{hours}h #{minutes}m #{'%.2f' % seconds}s"
      elsif minutes.positive?
        "#{minutes}m #{'%.2f' % seconds}s"
      else
        "#{'%.3f' % seconds}s"
      end
    end
  end
end
