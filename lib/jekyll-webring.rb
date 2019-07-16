# frozen_string_literal: true

require 'rss'
require 'open-uri'
require 'abbreviato'
require 'sanitize'

module Jekyll
	module Webring
		FeedItem = Struct.new(:source_title, :source_url, :title, :url, :date, :summary)

		@feeds = [];
		@url = 'https://christine.website/blog.rss'
		@max = 256

		def self.feeds ()
			if @feeds.empty?
				open @url do |rss|
					feed = []
					raw_feed = RSS::Parser.parse rss
					raw_feed.items.each do |item|
						sanitized = Sanitize.fragment item.content_encoded, Sanitize::Config::BASIC
						summary, _ = Abbreviato.truncate sanitized, max_length: @max
						feed << FeedItem.new(raw_feed.channel.title, raw_feed.channel.link,
								item.title, item.link, item.pubDate, summary)
					end
					@feeds << feed
				end
			end

			@feeds
		end
	end

	class WebringTag < Liquid::Tag
		def initialize (tag_name, text, tokens)
			super
			@text = text
		end

		def get_value (context, expression)
			lookup_path = expression.split('.')
			result = context
			lookup_path.each do |variable|
				result = result[variable] if result
			end

			result
		end

		def render (context)
			date = get_value(context, @text.strip)
			feeds = Jekyll::Webring.feeds

			items = []
			feeds.each do |feed_items|
				feed_items.each do |item|
					if item.date < date
						items << item
						break
					end
				end

				if items.length > 2
					break
				end
			end

			html = <<~HTML
				<section class="webring">
					<h3>Articles from blogs I follow around the net</h3>
					<section class="articles">
			HTML

			items.each do |item|
				html += <<~HTML
					<div class="article">
						<h4 class="title">
							<a href="#{ item.url }" target="_blank" rel="noopener">#{ item.title }</a>
						</h4>
						<p class="summary">#{ item.summary }</p>
						<small class="source">
							via <a href="#{ item.source_url }">#{ item.source_title }</a>
						</small>
						<small class="date">#{ item.date }</small>
					</div>
				HTML
			end

			html += <<~HTML
					</section>
				</section>
			HTML

			html
		end

	end

end

Liquid::Template.register_tag('webring', Jekyll::WebringTag)
