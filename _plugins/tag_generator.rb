# _plugins/tag_generator.rb
module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      lang = site.active_lang || site.config['default_lang'] || 'ko'
      all_tags = site.posts.docs
        .select { |p| p.data['lang'] == lang }
        .flat_map { |p| p.data['tags'] || [] }
        .map(&:to_s)
        .uniq
        .sort

      all_tags.each do |tag|
        site.pages << TagPage.new(site, site.source, tag, lang)
      end
    end
  end

  class TagPage < Page
    def initialize(site, base, tag, lang)
      @site = site
      @base = base
      tag_slug = tag.downcase.gsub(' ', '-')
      default_lang = site.config['default_lang'] || 'ko'
      # For the default language, polyglot outputs to _site/ directly, so we need
      # the lang prefix in @dir to get _site/ko/tags/... For other languages,
      # polyglot already prefixes the destination with /lang/, so we omit it.
      @dir  = if lang == default_lang
                "#{lang}/tags/#{tag_slug}"
              else
                "tags/#{tag_slug}"
              end
      @name = 'index.html'

      process(@name)
      read_yaml(File.join(base, '_layouts'), "tag-#{lang}.html")
      data['tag']    = tag
      data['lang']   = lang
      data['title']  = lang == 'ko' ? "태그: #{tag}" : "Tag: #{tag}"
      data['layout'] = "tag-#{lang}"
      data['slug']   = "tag-#{tag_slug}"
    end
  end
end
