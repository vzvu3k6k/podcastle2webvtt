require "webvtt"

# FIXME: TmpFile and TmpCue are not good names.

class WebVTT::TmpFile < WebVTT::File
  attr_accessor :header

  def initialize
    @cues = []
    @header = "WEBVTT FILE"
  end
end

class WebVTT::TmpCue < WebVTT::Cue
  def initialize
    @style = {}
  end
end
