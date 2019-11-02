# frozen_string_literal: true

require 'feedjira'
require 'httparty'
require 'sanitize'
require 'yaml'
require 'fileutils'

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
						<small class="date">{{ item.date }}</small>
					</div>
					{% endfor %}
				</section>
			</section>
		HTML

		CONFIG = Jekyll.configuration({})['webring']
		LAYOUT_FILE = "#{ Jekyll.configuration['layouts_dir'] }/#{ CONFIG['layout_file'] }.html"
		DATA_FILE = "#{ Jekyll.configuration['data_dir'] }/#{ CONFIG['data_file'] }.yml"
		DATE_FORMAT = CONFIG['date_format'] || Jekyll.configuration['date_format'] || "%-d %B, %Y"

		@max_summary_length = CONFIG['max_summary_length'] || 256

		@feeds = [];
		def self.feeds ()
			if @feeds.empty?
				urls = CONFIG['feeds']

				urls.each do |url|
					feed = []
					xml = HTTParty.get(url).body
					raw_feed = Feedjira.parse(xml)
					raw_feed.entries.each do |item|
						sanitized = Sanitize.fragment(item.content || item.summary)
						summary = sanitized.length > @max_summary_length ?
							"#{ sanitized[0 ... @max_summary_length] }..." : sanitized

						feed_item = {
							'source_title' => raw_feed.title,
							'source_url'   => raw_feed.url,
							'title'        => item.title,
							'url'          => item.url,
							'_date'        => item.published,
							'summary'      => summary,
						}

						feed << feed_item
					end
					@feeds << feed
				end
			end

			@feeds
		end

		@data = nil
		def self.get_data (site)
			unless @data
				@data = site.data['webring'] || {}
			end

			@data
		end
	end

	class WebringTag < Liquid::Tag
		def initialize (tag_name, text, tokens)
			super
			@text = text
		end

		def get_value (context, expression)
			result = nil

			unless expression.empty?
				lookup_path = expression.split('.')
				result = context
				lookup_path.each do |variable|
					result = result[variable] if result
				end
			end

			result
		end

		def get_items_from_feeds (param)
			items = []

			feeds = Jekyll::Webring.feeds
			case param
				when 'random'
					feeds.each do |feed_items|
						items << feed_items.sample
					end
				when Time, '', nil 
					date = param || Time.now
					feeds.each do |feed_items|
						item_to_add = nil

						feed_items.each do |item|
							if item['_date'] < date
								item_to_add = item
								break
							end
						end

						if item_to_add
							items << item_to_add
							next
						end

						case Jekyll::Webring::CONFIG['no_item_at_date_behaviour']
							when 'use_oldest'
								items << feed_items.last
							when 'use_latest'
								items << feed_items.first
							when 'random'
								items << feed_items.sample
							when 'ignore', ''
								next
						end
					end
			end

			items = items.sort_by { |item| item['_date'] }

			items
		end

		def render (context)
			site = context.registers[:site]
			param = get_value(context, @text.strip)

			webring_data = Jekyll::Webring.get_data(site)

			if webring_data[param]
				items = webring_data[param]
			else
				items = get_items_from_feeds(param)
				webring_data[param] = items if param

				if Jekyll::Webring::CONFIG['data_file']
					filename = Jekyll::Webring::DATA_FILE
					dirname = File.dirname filename
					unless File.directory? dirname
						FileUtils.mkdir_p dirname
					end

					File.open(filename, 'w') do |file|
						file.write(webring_data.to_yaml)
					end
				end
			end

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

			webring_items = items.take(Jekyll::Webring::CONFIG['num_items'] || 3)
			webring_items.each { |item| item['date'] = item['_date'].strftime(Jekyll::Webring::DATE_FORMAT) }

			payload['webring'] = webring_items

			template.render!(payload, info)
		end
	end
end

Liquid::Template.register_tag('webring', Jekyll::WebringTag)
