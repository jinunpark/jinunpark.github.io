# test/test_diagram_renderer.rb
require 'minitest/autorun'
require 'cgi'

# Load plugin without triggering Jekyll::Hooks (not available in test env)
module Jekyll
  module Hooks
    def self.register(*); end
  end
  module Logger
    def self.warn(*); end
  end
end

require_relative '../_plugins/diagram_renderer'

MERMAID_HTML = <<~HTML
  <div class="language-mermaid highlighter-rouge"><div class="highlight"><pre class="highlight"><code>flowchart LR
    A --&gt; B
  </code></pre></div></div>
HTML

PLANTUML_HTML = <<~HTML
  <div class="language-plantuml highlighter-rouge"><div class="highlight"><pre class="highlight"><code>@startuml
  Alice -&gt; Bob: Hello
  @enduml
  </code></pre></div></div>
HTML

FAKE_SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50"><text x="10" y="25">diagram</text></svg>'

class TestDiagramRenderer < Minitest::Test
  # --- wrap ---

  def test_wrap_produces_diagram_div_with_label
    result = DiagramRenderer.wrap(FAKE_SVG, 'mermaid')
    assert_includes result, '<div class="diagram">'
    assert_includes result, FAKE_SVG
    assert_includes result, '<p class="diagram-label">mermaid</p>'
  end

  def test_wrap_strips_xml_declaration
    svg_with_xml_decl = %Q(<?xml version="1.0" encoding="utf-8"?>\n#{FAKE_SVG})
    result = DiagramRenderer.wrap(svg_with_xml_decl, 'plantuml')
    refute_includes result, '<?xml'
    assert_includes result, '<svg'
  end

  # --- process with mocked renderers ---

  def test_process_replaces_mermaid_block
    DiagramRenderer.stub(:render_mermaid, FAKE_SVG) do
      result = DiagramRenderer.process(MERMAID_HTML)
      assert_includes result, '<div class="diagram">'
      assert_includes result, FAKE_SVG
      assert_includes result, '<p class="diagram-label">mermaid</p>'
      refute_includes result, 'highlighter-rouge'
    end
  end

  def test_process_replaces_plantuml_block
    DiagramRenderer.stub(:render_plantuml, FAKE_SVG) do
      result = DiagramRenderer.process(PLANTUML_HTML)
      assert_includes result, '<div class="diagram">'
      assert_includes result, FAKE_SVG
      assert_includes result, '<p class="diagram-label">plantuml</p>'
      refute_includes result, 'highlighter-rouge'
    end
  end

  def test_process_leaves_non_diagram_html_unchanged
    html = '<p>Hello world</p>'
    assert_equal html, DiagramRenderer.process(html)
  end

  def test_process_decodes_html_entities_before_rendering
    captured = nil
    stubbed = ->(source) { captured = source; FAKE_SVG }
    DiagramRenderer.stub(:render_mermaid, stubbed) do
      DiagramRenderer.process(MERMAID_HTML)
    end
    assert_includes captured, 'A --> B'
    refute_includes captured, '&gt;'
  end

  # --- graceful fallback ---

  def test_process_leaves_block_unchanged_when_render_returns_nil
    DiagramRenderer.stub(:render_mermaid, nil) do
      result = DiagramRenderer.process(MERMAID_HTML)
      assert_includes result, 'highlighter-rouge'
    end
  end
end
