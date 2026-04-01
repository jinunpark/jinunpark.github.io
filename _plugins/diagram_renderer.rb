# _plugins/diagram_renderer.rb
require 'cgi'
require 'open3'
require 'tempfile'

module DiagramRenderer
  # Matches the exact HTML structure kramdown+rouge produces for fenced code blocks.
  # The outer div class is "language-{type} highlighter-rouge".
  BLOCK_PATTERN = %r{
    <div\ class="language-(mermaid|plantuml)\ highlighter-rouge">
    <div\ class="highlight">
    <pre\ class="highlight"><code>(.*?)</code></pre>
    </div></div>
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
    warn "[DiagramRenderer] Failed to render #{type}: #{e.message}"
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
      _stdout, stderr, status = Open3.capture3(*cmd)
      unless status.success?
        warn "[DiagramRenderer] mmdc failed: #{stderr}"
        return nil
      end

      File.read(output.path)
    ensure
      input.unlink
      output.unlink
    end
  end

  def self.render_plantuml(source)
    jar = ENV.fetch('PLANTUML_JAR', File.join(Dir.pwd, 'plantuml.jar'))
    unless File.exist?(jar)
      warn "[DiagramRenderer] plantuml.jar not found at #{jar} (set PLANTUML_JAR env var to override)"
      return nil
    end

    svg, stderr, status = Open3.capture3('java', '-jar', jar, '-tsvg', '-pipe', stdin_data: source)
    unless status.success?
      warn "[DiagramRenderer] plantuml failed: #{stderr}"
      return nil
    end

    svg
  end

  def self.wrap(svg, type)
    svg = svg.sub(/\A\s*<\?xml[^>]*\?>\s*/m, '').strip
    %(<div class="diagram">#{svg}<p class="diagram-label">#{type}</p></div>)
  end

  def self.tool_available?(name)
    system("which #{name} > /dev/null 2>&1")
  end
end

Jekyll::Hooks.register [:pages, :posts], :post_render do |doc|
  next unless doc.output_ext == '.html'

  doc.output = DiagramRenderer.process(doc.output)
end
