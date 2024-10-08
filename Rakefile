require 'bundler/setup'
Bundler.require

def directory? path
  File.directory? path
end

def ref(raw_ref: ENV['REF'])
  raw_ref or raise "Please set a REF env variable, e.g. `env REF=v0.8.0 rake doc`\n\n"
end

def components
  components = ENV['COMPONENTS'].to_s
  components = 'lib corelib stdlib' if components.empty?
  components.split(/\W+/)
end

# The path to a local checkout of Opal, will use `ref` just to generate
# documentation titles and target folders. E.g. `env LOCAL="../opal" rake …`
local = ENV['LOCAL']

opal_dir = local || 'opal'

task :setup do
  unless local
    directory? 'opal' or sh 'git clone https://github.com/opal/opal.git opal'
    Dir.chdir 'opal' do
      sh "git fetch --all"
      sh "git reset --hard"
      sh "git clean -fx"
      sh "git checkout --detach #{ref}"
    end
  end

  directory? 'gh-pages' or sh 'git clone git@github.com:opal/docs.git gh-pages --reference . -b gh-pages'
  Dir.chdir 'gh-pages' do
    sh "git reset --hard"
    sh "git clean -fx"
    sh "git checkout gh-pages"
  end unless ENV['SKIP_GH_PAGES_RESET']
end

def base_title
  "Opal #{pretty_ref(ref)}"
end

def pretty_ref(ref)
  ref.tr('-', '.').sub('stable', 'x')
end

task :api => :setup do
  base_dir   = "gh-pages/api/#{ref}"

  # Still need to decide how to format the runtime, for now let's just put it
  # in a markdown file and render it as it is.
  runtime_path = "#{opal_dir}/opal/corelib/runtime.js"

  markdown_lines = runtime_markdown(runtime_docs(File.read runtime_path))
  File.write "#{opal_dir}/opal/corelib/RUNTIME.md", markdown_lines.join("\n")

  ruby_lines = runtime_ruby(runtime_docs(File.read runtime_path))
  File.write "#{opal_dir}/opal/corelib/runtime.js.rb", ruby_lines.join("\n")

  components.each do |component|
    yard(component: component, base_dir: base_dir, base_title: base_title)
  end
end

task :guides => :setup do
  base_dir   = "gh-pages/guides/#{ref}"

  pygments_css = Pygments.css(style: 'colorful')
  css = <<-CSS
  body {font-family: sans-serif;}
  #{pygments_css}
  CSS

  target_paths = []
  files = Dir["#{opal_dir}/docs/*.md"]
  title_for = -> file do
    File.read(file).scan(/^#([^#].*?)$/).flatten.first.strip
  rescue
    warn "ERROR: missing a title for #{file}, looking for a subtitle"
    File.read(file).scan(/^#+([^#].*?)$/).flatten.first.strip
  end
  target_for = -> file { File.basename(file).sub('.md', '.html') }
  mkdir_p base_dir

  is_index = -> { _1.end_with? 'index.md' }

  files.each do |path|
    html_contents = markdown(File.read(path))
    target_path = target_for[path]
    title = title_for[path]
    puts "#{path.ljust 40} → #{title}"
    html_title = "#{base_title} · #{title}"
    html_nav = %{<nav><a href="./index.html">« Back to index</a></nav><hr>}
    html_footer = %{<footer><hr/>
      You're encouraged to help improve the quality of this guide.
      Please contribute if you see any typos, factual errors, or missing information.<br/>
      To get started, <a href="https://github.com/opal/opal/tree/master/docs">head to the docs folder in the main repo</a>.
    </footer>}

    html_body = <<-HTML
      #{html_nav unless is_index[path]}
      #{html_contents}
      #{html_footer}
    HTML

    File.write "#{base_dir}/#{target_path}", html_template(html_body, title: html_title, css: css)
  end

  unless files.any?(is_index)
    html_title = "#{base_title} · Guides"
    html_body = %{
      <h1>#{html_title}</h1>
      <ul>
        #{files.map {|t| "<li><a href='./#{target_for[t]}'>#{title_for[t]}</a></li>"}.join}
      </ul>
    }
    File.write "#{base_dir}/index.html", html_template(html_body, title: html_title)
  end
end

task :index do
  html_title = 'Opal · Documentation Central'
  version_sorting = -> v {
    segments = v.split('.').map do |segment|
      if segment =~ /^\d+$/
        -(segment.to_i)
      else
        segment
      end
    end
    segments [3] ||= '0' # if we have not beta/rc/etc let's use the string "0"
    segments
  }

  sorting = -> v {
    case v
    when /^v/
      ['1_version', *version_sorting[v[1..-1]]]
    else
      ['0_branch']
    end
  }

  api_versions    = Dir['gh-pages/api/*/*/index.html' ].map{|f| f.scan(%r{/api/([^/]+)/})   }.flatten.uniq.sort_by(&sorting)
  guides_versions = Dir['gh-pages/guides/*/index.html'].map{|f| f.scan(%r{/guides/([^/]+)/})}.flatten.uniq.sort_by(&sorting)

  api_versions.each do |version|
    ENV['REF'] = version
    components_index(base_title: base_title, components: components, base_dir: "gh-pages/api/#{version}")
  end

  api_path    = -> v { "./api/#{v}/index.html" }
  guides_path = -> v { "./guides/#{v}/index.html" }

  stable_v = (api_versions - ['master']).sort_by { |v| Gem::Version.new(v.sub(/^v/, '')) }.last

  stable_html = <<-HTML
    <div class="jumbotron">
      <h1>#{pretty_ref(stable_v)} <small>stable</small></h1>
      <p><a href="https://github.com/opal/opal/blob/master/CHANGELOG.md">See the full Changelog to see <b>what's new</b></a></p>
      <p>
        <a class="btn btn-primary btn-lg" href="#{api_path[stable_v]}" role="button">API Docs</a>
        <a class="btn btn-primary btn-lg" href="#{guides_path[stable_v]}" role="button">Guides</a>
      </p>
    </div>
  HTML

  api_html = <<-HTML
    <div style="float: left; min-width: 50%;">
      <h3>API Docs</h3>
      <ul>
        #{api_versions.map {|v| "<li><a href='#{api_path[v]}'>#{pretty_ref(v)}</a></li>"}.join}
      </ul>
    </div>
  HTML

  guides_html = <<-HTML
    <div style="float: left; min-width: 50%;">
      <h3>Guides</h3>
      <ul>
        #{guides_versions.map {|v| "<li><a href='#{guides_path[v]}'>#{pretty_ref(v)}</a></li>"}.join}
      </ul>
    </div>
  HTML

  other_versions_html = <<-HTML
    <div class="well">
      <h2>All versions</h2>
      #{guides_html}
      #{api_html}
      <div style="clear:both"></div>
    </div>
  HTML

  html_body = <<-HTML
  <div class="page-header">
    <h1>#{html_title}</h1>
  </div>
  #{stable_html}
  #{other_versions_html}
  HTML


  File.write "gh-pages/index.html", html_template(html_body, title: html_title)
end

def sdoc(component:, base_dir:, base_title:)
  target = case component
           when 'corelib' then 'opal/opal'
           when 'stdlib'  then 'opal/stdlib'
           when 'lib'     then 'opal/lib'
           end

  sh %{
    sdoc
    --format sdoc
    --markup tomdoc
    --github
    --output #{base_dir}/#{component}
    --title "#{base_title} · #{component}"
    --hyperlink-all
    #{target}
  }.gsub(/\n */, " ").strip
end

def yard(component:, base_dir:, base_title:)
  target = case component
           when 'corelib' then 'opal/opal'
           when 'stdlib'  then 'opal/stdlib'
           when 'lib'     then 'opal/lib'
           end

  target = File.expand_path(target)
  without_root = -> path { File.expand_path(path)[(File.expand_path(__dir__).size+1)..-1] }
  output = "#{__dir__}/#{base_dir}/#{component}"
  rm_rf "#{output}/*"
  sh %{
    yardoc
    --template-path="#{__dir__}/templates/yard/"
    --output=#{output}
    --title="#{component} (#{base_title})"
    --db="#{__dir__}/.yardoc-#{base_dir.downcase.gsub(/[^a-z\d]/,'-')}-#{component}"
    --exclude 'node_modules'
    --markup="markdown"
    --no-cache
    --main #{without_root[target]}/README.md
    '#{without_root[target]}/**/*.rb' '#{without_root[target]}/**/*.js.rb'
    -
    #{without_root[target]}/**/*.md
  }.gsub(/\n */, " ").strip
end

def components_index(base_title:, components:, base_dir:)
  html_title = "#{base_title} API Documentation Index"
  html_body = <<-HTML
    <h1>#{html_title}</h1>
    <ul>
      #{components.map {|c| "<li><a href='./#{c}/index.html'>#{c}</a></li>"}.join}
    </ul>
  HTML

  File.write "#{base_dir}/index.html", html_template(html_body, title: html_title)
end

class HTMLwithPygments < Redcarpet::Render::HTML
  def block_code(code, language)
    language ||= 'text'
    Pygments.highlight(code, lexer: language)
  rescue
    Pygments.highlight(code, lexer: 'text')
  end

  NOTES_REGEXP = '^(TIP|IMPORTANT|CAUTION|WARNING|NOTE|INFO|TODO)[.:](.*?)'

  def paragraph(text)
    if text =~ /#{NOTES_REGEXP}/
      convert_notes(text)
    else
      "<p>#{text}</p>"
    end
  end

  def convert_notes(body)
    # The following regexp detects special labels followed by a
    # paragraph, perhaps at the end of the document.
    #
    # It is important that we do not eat more than one newline
    # because formatting may be wrong otherwise. For example,
    # if a bulleted list follows the first item is not rendered
    # as a list item, but as a paragraph starting with a plain
    # asterisk.
    body.gsub(/#{NOTES_REGEXP}(\n(?=\n)|\Z)/m) do
      css_class = case $1
                  when 'CAUTION', 'IMPORTANT'
                    'warning'
                  when 'TIP'
                    'info'
                  else
                    $1.downcase
                  end
      %(<div class="#{css_class}"><p>#{$2.strip}</p></div>)
    end
  end
end

def markdown(text)
  renderer = HTMLwithPygments.new(:hard_wrap => true, :filter_html => true)
  options = {
    :autolink            => true,
    :space_after_headers => true,
    :fenced_code_blocks  => true,
    :tables              => true,
    :strikethrough       => true,
    :smart               => true,
    :hard_wrap           => true,
    :safelink            => true,
    :no_intraemphasis    => true,
  }
  Redcarpet::Markdown.new(renderer, options).render(text)
end

def html_template(html, title:, css: '')
  require 'ostruct'
  require 'erb'
  require 'pathname'
  templates = Pathname(__dir__+'/templates')
  current_page = OpenStruct.new(data: OpenStruct.new(title: title))
  page_classes = OpenStruct.new
  css = templates.join('application.css').read + css.to_s
  ERB.new(templates.join('layout.erb').read).result(binding)
end

# @returns some fake ruby code containing the docs and the code coming from runtime.js
def runtime_docs(runtime_js_code)
  lines = runtime_js_code.split("\n")
  functions = []
  in_comment = false
  scan_block_comment = -> lines {
    next if lines.empty?
    next unless lines.first.to_s.strip.start_with?('/*')
    lines.shift # skip the start
    comment = []
    comment << lines.shift.strip.gsub(/^\*+ /, '') until lines.first.strip.end_with? '*/'
    lines.shift # skip the end
    comment
  }
  scan_line_comment = -> lines {
    next if lines.empty?
    next unless lines.first.strip.start_with? '//'
    comment = []
    comment << lines.shift.strip.gsub(%r{^// ?}, '') while lines.first.strip.start_with? '//'
    comment
  }
  skip_blank_lines = -> lines {
    next if lines.empty?
    lines.shift if lines.first.strip.empty?
  }
  scan_function_body = -> lines {
    next if lines.empty?
    next unless lines.first =~ /\bfunction[^}]*$/
    indentation = lines.first.scan(/^(\s*)\S/).flatten.first
    body = [lines.shift]
    until lines.first =~ /^#{indentation}\};?/
      body << lines.shift
    end
    body << lines.shift # the closure
    body
  }

  scan_line = -> lines {
    line = lines.shift
    [line]
  }
  until lines.empty?
    current ||= {}

    # we're done with this
    if current[:body]
      functions << current
      current = nil
      next
    end

    current[:comment] = scan_block_comment[lines] || scan_line_comment[lines]
    if current[:comment]
      current[:body] = scan_function_body[lines] || scan_line[lines]
    else
      lines.shift
    end
  end

  functions
end

def runtime_markdown(data)
  extract_function_name = -> first_line {
    function_args = ' *\(([^\)]*)\)\{'
    first_line = first_line.strip.chomp(';').chomp("{").sub(/^var /, '').strip
    case first_line
    when /\W((?:Opal\.)?\w+) *= *function#{function_args}/ then "function: `#{$1}(#{$2}})`"
    when /function *(\w+)#{function_args}/                 then "function: `#{$1}(#{$2})`"
    else "`#{first_line}`"
    end
  }

  markdown = [
    '# runtime.js'
  ]

  data.each do |hash|
    comment:, body: = **hash

    markdown << "## #{extract_function_name[body.first]}"
    markdown << ""
    markdown += comment
    markdown << ""
    markdown << "```js"
    lead_space = body.first.scan(/^( *)/).flatten.first
    markdown += body.map{|line| line.gsub(/^#{lead_space}/, '') }
    markdown << "```"
    markdown << ""
    markdown << ""
  end

  markdown
end

def runtime_ruby(data)
  extract_function_name = -> line {
    next unless line =~ /function/

    name = line.scan(/Opal\.\w+|function +(\w+)/).flatten.first
    args = line.scan(/function[^(]*\(([^(]*)\)/).flatten.first
    return name, args
  }

  ruby = []

  data.each do |hash|
    comment:, body: = **hash

    method_name, method_args = extract_function_name[body.first]
    next if method_name.nil? or method_name =~ /^[A-Z]/

    ruby += comment.map {|l| "# #{l.gsub("@returns", "@return")}"}
    # ruby << "define_method #{method_name.inspect} do |*args|"
    ruby << "def self.#{method_name}(*)"
    ruby << "<<-JAVASCRIPT"
    lead_space = body.first.scan(/^( *)/).flatten.first
    ruby += body.map{|line| "   "+line.gsub(/^#{lead_space}/, '') }
    ruby << "JAVASCRIPT"
    ruby << "end"
    ruby << ""
    ruby << ""
  end

  [
    'module __JS__',
    %Q{  # This module is just a placeholder for showing the documentation of the},
    %Q{  # internal JavaScript runtime. The methods you'll find defined below},
    %Q{  # are actually JavaScript functions attached to the `Opal` global object},
    %Q{  module Opal},
  ] + ruby.map {|l| '    '+l} + [
    %Q{  end},
    %Q{end},
  ]
end

# FOR FUTURE REF:
#
#   DOCCO/GROC
#   path = 'opal/opal/corelib/runtime.js'
#   contents = File.read path
#   normalized_contents = contents.gsub(%r{^(\s)*(?m:/\*.*?\*/ *$)}) do |match|
#     lines = match.strip.split("\n")
#     leading = lines.first.scan(/^ */).first + '// '
#     normalized = lines.map do |line|
#       line.sub(%r{^ *(?:/\*+|\* +|\*/|(?=[\S]|$))}, leading)
#     end.compact.join("\n")
#     "\n"+normalized
#   end
#   File.write path, normalized_contents
#   puts normalized_contents
#   # sh "groc --root opal/opal/corelib --output #{base_dir} runtime.js"
#   sh "docco --output #{base_dir} opal/opal/corelib/runtime.js"
#   File.write path, contents
#
#   DOXX
#   command = "doxx --template #{doc_repo.join('doxx-templates/opal.jade')} "\
#             "--source opal/corelib --target #{doc_base}/#{git}/#{name} "\
#             "--title \"Opal runtime.js Documentation\" --readme opal/README.md"
#   puts command; system command or $stderr.puts "Please install doxx with: npm install"


task default: [:api, :guides]
