class PodcastleTranscript < Array
  class << self
    def parse(html)
      require "nokogiri"
      require "json"

      document = Nokogiri::HTML.parse(html)

      script = document.search("script").find {|i|
        i.text.include?("var startTimes = ")
      }
      start_times = JSON.parse(
        script.text.match(/var startTimes = (.+?);/)[1]
      )

      _transcript = document.at_css("#proof").children.map {|node|
        case node.name
        when "span"
          { type: :text,
            content: node.text,
            likelihood: node.attr("class").match(/\blh_(\d)\b/)[1].to_i,
            start_time: start_times.shift.to_f, # 誤差が気になる

            # Node#matches? is slow when the node has many siblings.
            is_modified: /\bmodified\b/ === node.attr("class"),
            is_checked: /\bchecked\b/ === node.attr("class"),
          }
        when "strong"
          { type: :speaker,
            content: node.text.sub(/: $/, ''),
          }
        when "br"
          { type: :newline,
          }
        else
          raise "Unexpected node (<#{node.name}>)"
        end
      }

      PodcastleTranscript.new(_transcript)
    end
  end

  def segment
    chunks = [[]]
    self.each do |i|
      current_chunk = chunks.last
      if i[:type] == :speaker || i[:type] == :newline
        chunks.push([]) unless current_chunk.empty?
        next
      end
      if i[:type] == :text
        next if /\A[[:space:]]*\z/ === i[:content]
        chunks.last.push(i)
        length = current_chunk.last[:start_time] - current_chunk.first[:start_time]
        if length > 5
          chunks.push([])
        end
      end
    end
    chunks.pop if chunks.last.empty?
    chunks.push(nil)
    chunks.each_cons(2).map {|(chunk, next_chunk)|
      { start: chunk.first[:start_time],
        end: next_chunk ? next_chunk.first[:start_time] : chunk.last[:start_time],
        text: chunk.map{|i| i[:content]}.join,
      }
    }
  end

  def to_webvtt_file
    require_relative './webvtt'

    cues = self.segment.map {|chunk|
      WebVTT::TmpCue.new.tap do |cue|
        cue.start = WebVTT::Timestamp.new(chunk[:start])
        cue.end   = WebVTT::Timestamp.new(chunk[:end])
        cue.text = chunk[:text]
      end
    }

    WebVTT::TmpFile.new.tap do |webvtt|
      webvtt.cues = cues
    end
  end
end
