require 'bundler/setup'
Bundler.require

def directory? path
  File.directory? path
end

def ref(raw_ref: ENV['REF'])
  raw_ref or raise "Please set a REF env variable, e.g. `env REF=v0.8.0 rake doc`\n\n"
end

def components
  %w[lib corelib stdlib]
end

# The path to a local checkout of Opal, will use `ref` just to generate
# documentation titles and target folders. E.g. `env LOCAL="../opal" rake …`
local = ENV['LOCAL']

opal_dir = local || 'opal'

task :setup do
  unless local
    directory? 'opal' or sh 'git clone https://github.com/opal/opal.git opal'
    cd 'opal' do
      sh "git fetch --all"
      sh "git reset --hard"
      sh "git clean -fx"
      sh "git checkout --detach origin/#{ref}"
    end
  end

  directory? 'gh-pages' or sh 'git clone git@github.com:opal/docs.git gh-pages --reference . -b master'
  cd 'gh-pages' do
    sh "git reset --hard"
    sh "git clean -fx"
    sh "git checkout gh-pages"
  end
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
  # Below some possible alternative implementations with DOCCO/GROC/DOXX.
  path = "#{opal_dir}/opal/corelib/runtime.js"
  File.write "#{opal_dir}/opal/corelib/runtime.js.md", "# Opal Runtime:\n\n```js\n#{File.read path}\n```\n"

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
  title_for = -> file { File.read(file).scan(/^#([^#].*?)$/).flatten.first.strip }
  target_for = -> file { File.basename(file).sub('.md', '.html') }
  mkdir_p base_dir

  files.each do |path|
    html_contents = markdown(File.read(path))
    target_path = target_for[path]
    title = title_for[path]
    puts "#{path.ljust 40} → #{title}"
    html_title = "#{base_title} · #{title}"
    html_body = <<-HTML
      <nav>
        <a href="./index.html">« Back to index</a>
      </nav>
      <hr>
      #{html_contents}
    HTML

    File.write "#{base_dir}/#{target_path}", html_template(html_body, title: html_title, css: css)
  end

  html_title = "#{base_title} · Guides"
  html_body = %{
    <h1>#{html_title}</h1>
    <ul>
      #{files.map {|t| "<li><a href='./#{target_for[t]}'>#{title_for[t]}</a></li>"}.join}
    </ul>
  }
  File.write "#{base_dir}/index.html", html_template(html_body, title: html_title)
end

task :index do
  html_title = 'Opal · Documentation Central'

  api_versions    = Dir['gh-pages/api/*/*/index.html' ].map{|f| f.scan(%r{/api/([^/]+)/})   }.flatten.uniq.sort.reverse
  guides_versions = Dir['gh-pages/guides/*/index.html'].map{|f| f.scan(%r{/guides/([^/]+)/})}.flatten.uniq.sort.reverse

  api_versions.each do |version|
    ENV['REF'] = version
    components_index(base_title: base_title, components: components, base_dir: "gh-pages/api/#{version}")
  end

  api_html = <<-HTML
    <h3>API Docs</h3>
    <ul>
      #{api_versions.map {|v| "<li><a href='./api/#{v}/index.html'>#{pretty_ref(v)}</a></li>"}.join}
    </ul>
  HTML

  guides_html = <<-HTML
    <h3>Guides</h3>
    <ul>
      #{guides_versions.map {|v| "<li><a href='./guides/#{v}/index.html'>#{pretty_ref(v)}</a></li>"}.join}
    </ul>
  HTML

  html_body = <<-HTML
  <h1>#{html_title}</h1>
  #{guides_html}
  #{api_html}
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

  cd target do
    sh %{
      yard
      --output #{target.split('/').map{'..'}.join('/')}/#{base_dir}/#{component}
      --title "#{component} (#{base_title})"
      **/*.rb
    }.gsub(/\n */, " ").strip
  end
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
