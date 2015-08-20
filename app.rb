require "sinatra"
require "open-uri"
require_relative "./lib/podcastle"

get %r{\A/episode/(.+)/transcript.webvtt\z} do |episode_id|
  html = open(
    "http://podcastle.jp/episode/#{URI.encode_www_form_component(episode_id)}",
    "User-Agent" => "podcastle2webvtt",
  )
  transcript = PodcastleTranscript.parse(html)

  content_type "text/vtt"
  transcript.to_webvtt_file.to_webvtt
end
