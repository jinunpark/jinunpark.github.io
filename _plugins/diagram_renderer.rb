# _plugins/diagram_renderer.rb
require 'cgi'
require 'open3'
require 'securerandom'
require 'tempfile'

module DiagramRenderer
  # Matches what kramdown+rouge actually outputs for unknown languages (mermaid, plantuml).
  # Rouge does not recognize these languages, so it emits a plain <pre><code> without
  # the highlighter-rouge wrapper div.
  BLOCK_PATTERN = %r{
    <pre><code[^>]*\bclass="language-(mermaid|plantuml)\b[^"]*"[^>]*>(.*?)</code></pre>
  }mx

  def self.process(html)
    html.gsub(BLOCK_PATTERN) do
      type   = Regexp.last_match(1)
      source = CGI.unescapeHTML(Regexp.last_match(2)).strip
      svg    = render(type, source)
      svg ? wrap(svg, type) : Regexp.last_match(0)
    end
  end

  def self.render(type, source)
    case type
    when 'mermaid'  then render_mermaid(source)
    when 'plantuml' then render_plantuml(source)
    end
  rescue StandardError => e
    Jekyll.logger.warn "DiagramRenderer:", "Failed to render #{type}: #{e.message}"
    nil
  end

  def self.render_mermaid(source)
    return nil unless tool_available?('mmdc')

    input  = Tempfile.new(['mermaid', '.mmd'])
    output = Tempfile.new(['mermaid', '.svg'])
    begin
      input.write(source)
      input.close
      output.close

      cmd = ['mmdc', '-i', input.path, '-o', output.path]
      puppeteer_cfg = File.join(Dir.pwd, 'puppeteer-config.json')
      cmd += ['-p', puppeteer_cfg] if File.exist?(puppeteer_cfg)
      _stdout, stderr, status = Open3.capture3(*cmd)
      unless status.success?
        Jekyll.logger.warn "DiagramRenderer:", "mmdc failed: #{stderr.strip}"
        return nil
      end

      expand_viewbox(File.read(output.path))
    ensure
      input.unlink
      output.unlink
    end
  end

  def self.render_plantuml(source)
    jar = ENV.fetch('PLANTUML_JAR', File.join(Dir.pwd, 'plantuml.jar'))
    unless File.exist?(jar)
      Jekyll.logger.warn "DiagramRenderer:", "plantuml.jar not found at #{jar} (set PLANTUML_JAR env var to override)"
      return nil
    end

    svg, stderr, status = Open3.capture3('java', '-jar', jar, '-tsvg', '-pipe', stdin_data: source)
    unless status.success?
      Jekyll.logger.warn "DiagramRenderer:", "plantuml failed: #{stderr.strip}"
      return nil
    end

    svg
  end

  def self.expand_viewbox(svg, pad = 10)
    svg.sub(/(<svg\b[^>]*\sviewBox=")([^"]+)(")/i) do
      parts = Regexp.last_match(2).split.map(&:to_f)
      if parts.length == 4
        x, y, w, h = parts
        "#{Regexp.last_match(1)}#{x - pad} #{y - pad} #{w + pad * 2} #{h + pad * 2}#{Regexp.last_match(3)}"
      else
        Regexp.last_match(0)
      end
    end
  end

  def self.wrap(svg, type)
    svg = svg.sub(/\A\s*<\?xml[^>]*\?>\s*/m, '').strip
    unique_id = "diagram-#{type}-#{SecureRandom.hex(6)}"
    svg = svg.gsub(/\bid="my-svg"/, %Q(id="#{unique_id}"))
             .gsub(/#my-svg\b/, "##{unique_id}")
    %(<div class="diagram">#{svg}<p class="diagram-label">#{type}</p></div>)
  end

  def self.tool_available?(name)
    system('which', name, out: File::NULL, err: File::NULL)
  end
end

Jekyll::Hooks.register [:pages, :posts], :post_render do |doc|
  next unless doc.output_ext == '.html'

  doc.output = DiagramRenderer.process(doc.output)
end
