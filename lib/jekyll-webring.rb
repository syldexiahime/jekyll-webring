# frozen_string_literal: true

require 'rss'
require 'open-uri'
require 'sanitize'

module Jekyll
	module Webring
		TEMPLATE = <<~HTML
			<section class="webring">
				<h3>Articles from blogs I follow around the net</h3>
				<section class="articles">
					{% for item in webring %}
					<div class="article">
						<h4 class="title">
							<a href="{{ item.url }}" target="_blank" rel="noopener">{{ item.title }}</a>
						</h4>
						<p class="summary">{{ item.summary }}</p>
						<small class="source">
							via <a href="{{ item.source_url }}">{{ item.source_title }}</a>
						</small>
						<small class="date">{{ item.date | date '%-d %B, %Y' }}</small>
					</div>
					{% endfor %}
				</section>
			</section>
		HTML

		CONFIG = Jekyll.configuration({})['webring']
		LAYOUT_FILE = "#{ Jekyll.configuration['layouts_dir'] }/#{ CONFIG['layout_file'] }.html"

		@max_summary_length = CONFIG['max_summary_length'] || 256

		@feeds = [];
		def self.feeds ()
			if @feeds.empty?
				urls = CONFIG['feeds']

				urls.each do |url|
					open url do |rss|
						feed = []
						raw_feed = RSS::Parser.parse rss
						raw_feed.items.each do |item|
							sanitized = Sanitize.clean (item.content_encoded || item.description)
							summary = "#{ sanitized[0 ... @max_summary_length] }"

							feed_item = {
								'source_title' => raw_feed.channel.title,
								'source_url'   => raw_feed.channel.link,
								'title'        => item.title,
								'url'          => item.link,
								'date'         => item.date,
								'summary'      => summary
							}

							feed << feed_item
						end
						@feeds << feed
					end
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
					if item['date'] < date
						items << item
						break
					end
				end

				if items.length > 2
					break
				end
			end

			site = context.registers[:site]
			liquid_opts = site.config['liquid']

			content = Jekyll::Webring::TEMPLATE
			payload = context

			# stuff beyond this point mainly hacked together from jekyll internals
			filename = Jekyll::Webring::LAYOUT_FILE
			if File.file? filename
				begin
					content = File.read filename
					if content =~ Document::YAML_FRONT_MATTER_REGEXP
						content = $POSTMATCH
						payload = payload.merge SafeYAML.load(Regexp.last_match(1))
					end
				rescue Psych::SyntaxError => e
					Jekyll.logger.warn "YAML Exception reading #{filename}: #{e.message}"
					raise e if site.config["strict_front_matter"]
				rescue StandardError => e
					Jekyll.logger.warn "Error reading file #{filename}: #{e.message}"
					raise e if site.config["strict_front_matter"]
				end
			end

			template = site.liquid_renderer.file((File.file? filename) ? filename : '').parse(content)

			info = {
				:registers        => { :site => site, :page => context['page'] },
				:strict_filters   => liquid_opts['strict_filters'],
				:strict_variables => liquid_opts['strict_variables'],
			}

			payload['webring'] = items

			template.render!(payload, info)
		end
	end
end

Liquid::Template.register_tag('webring', Jekyll::WebringTag)
