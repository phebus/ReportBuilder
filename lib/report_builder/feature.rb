# frozen_string_literal: true

module ReportBuilder
  class Feature < OpenStruct
    attr_accessor :scenarios

    def initialize
      super

      self.name = ERB::Util.html_escape(self.name) if self.keyword == 'Feature'
    end

    def normalize_elements
      process_backgrounds if self.elements.first.type == 'background'
      process_scenarios

      self.status   = feature_status
      self.duration = total_time(self.elements)
    end

    def failed_scenarios
      elements.select { |element| element.status == 'failed' }
    end

    def broken?
      status == 'broken'
    end

    private

    def process_scenarios
      self.elements.each do |scenario|
        scenario.name = ERB::Util.html_escape scenario.name

        process_before(scenario)
        process_steps(scenario)
        process_after(scenario)

        scenario.status   = scenario_status(scenario)
        scenario.duration = total_time(scenario.before) + total_time(scenario.steps) + total_time(scenario.after)
      end

      group_scenarios
    end

    def process_backgrounds
      (0..elements.size - 1).step(2) do |i|
        elements[i].steps ||= []
        elements[i].steps.each { |step| step.name += (' (' + elements[i].keyword + ')') }

        if elements[i + 1]
          elements[i + 1].steps  = elements[i].steps + elements[i + 1].steps
          elements[i + 1].before = elements[i].before if elements[i].before
        end
      end

      elements.reject! { |element| element.type == 'background' }
    end

    def process_before(scenario)
      scenario.before ||= []

      scenario.before.each do |before|
        before.result.duration ||= 0

        before.embeddings&.map! do |embedding|
          decode_embedding(embedding)
        end

        before.status   = before.result.status
        before.duration = before.result.duration
      end
    end

    def process_after_step(step)
      step.after&.each do |after|
        after.result.duration ||= 0
        @step_duration += after.result.duration
        @step_status   = 'failed' if after.result.duration == 'failed'

        after.embeddings&.map! do |embedding|
          decode_embedding(embedding)
        end

        after.status   = after.result.status
        after.duration = after.result.duration
      end
    end

    def process_steps(scenario)
      scenario.steps ||= []
      scenario.steps.each do |step|
        step.result.duration ||= 0
        step.name            = ERB::Util.html_escape step.name
        @step_duration       = step.result.duration
        @step_status         = step.result.status

        process_after_step(step)

        step.embeddings&.map! do |embedding|
          decode_embedding(embedding)
        end

        step.duration = @step_duration
        step.status   = @step_status
      end
    end

    def process_after(scenario)
      scenario.after ||= []
      scenario.after.each do |after|
        after.result.duration ||= 0

        after.embeddings&.map! do |embedding|
          decode_embedding(embedding)
        end

        after.status   = after.result.status
        after.duration = after.result.duration
      end
    end

    def group_scenarios
      grouped_scenarios = self.elements.group_by { |scenario| scenario.id + ':' + scenario.line.to_s }
      self.elements     = grouped_scenarios.values.map do |scenario_group|
        the_scenario      = scenario_group.find do |scenario|
          scenario.status == 'passed'
        end || scenario_group.last

        the_scenario.name += " (x#{scenario_group.size})" if scenario_group.size > 1

        the_scenario
      end
    end

    def decode_text(data)
      Base64.urlsafe_decode64 data
    rescue
      'Problem decoding text'
    end

    def decode_embedding(embedding)
      case embedding.mime_type
      when %r{^image/(png|gif|jpg|jpeg)}
        embedding.data = decode_image(embedding.data)
      when %r{^text/(plain|html)}
        embedding.data = decode_text(embedding.data)
      end

      embedding
    end

    def decode_image(data)
      base64 = %r{^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$}

      if data =~ base64
        begin
          data_base64 = Base64.urlsafe_decode64(data).gsub(%r{^data:image/(png|gif|jpg|jpeg);base64,}, '')
        rescue
          data
        end

        if data_base64 =~ base64
          data_base64
        else
          data
        end
      else
        ''
      end
    end

    def scenario_status(scenario)
      (scenario.before + scenario.steps + scenario.after).each do |step|
        status = step.status
        return status unless status == 'passed'
      end
      'passed'
    end

    def feature_status
      feature_status = 'working'
      self.elements.each do |scenario|
        status = scenario.status
        return 'broken' if status == 'failed'

        feature_status = 'incomplete' if %w(undefined pending).include?(status)
      end
      feature_status
    end

    def total_time(data)
      total_time = 0
      data.each { |item| total_time += item.duration }
      total_time
    end
  end
end
