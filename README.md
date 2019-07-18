# jekyll-webring plugin

[![Gem Version](https://badge.fury.io/rb/jekyll-webring.svg)](https://badge.fury.io/rb/jekyll-webring)

A plugin designed to generate a webring from rss feeds based on a date, so you can link to other blogs. Inspiried by [openring](https://git.sr.ht/~sircmpwn/openring).

## Installation

Add this line to your site's Gemfile:

```ruby
gem 'jekyll-webring'
```

And then add this line to your site's `_config.yml`:

```yml
plugins:
  - jekyll-webring
```

## Usage

Generate a webring by putting this in a liquid template

```liquid
{% webring %}
```

You can pass some options to the tag too. For example pass a date to generate a webring of articles written before that date:

```liquid
{% webring post.date %}
```

Or pass 'random' to select random items from the rss feeds given:

```liquid
{% webring 'random' %}
```

If the `layout_file` config option is set, you can create a liquid template for the webring. The default one looks like:

```liquid
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
```

## Configuration

```yaml
webring:
  # Will save and read data from _data/webring.yml
  # suggested to add this file to excludes in _config.yml otherwise jekyll watch will get stuck in a permanant regenerate loop
  # (I also suggest setting this if you want to guarantee having the same webring generated, as many feeds only show the most recent items
  # and will be unable to have a webring item generated for them if not saved)
  # default: nil
  data_file: webring

  # Will look for a liquid template at _layouts/webring.html, if not set will use a default template
  # default: nil
  layout_file: webring

  # Array of rss feed urls
  # default: nil
  feeds:
    - $RSS_FEED_URL

  # The max length of the summary of the article
  # default: 256
  max_summary_length: 256

  # The number of items to show in the webring
  # default: 3
  num_items: 3

  # What to do if a date is given and no items in the feed are older than that date
  # options: ignore, use_oldest, use_latest, random
  # default: ignore
  no_item_at_date_behaviour: use_oldest
```

## Contributing

If you'd like to contribute, please [send a patch](https://git-send-email.io) to this [mailing list](https://lists.sr.ht/~syldexia/public-inbox) [<~syldexia/public-inbox@lists.sr.ht>](mailto:~syldexia/public-inbox@lists.sr.ht)! (or just email feedback or issues or w/e)

I've not really used ruby before, so I'm sure my code is quite bad, and any contributions would be welcome!
