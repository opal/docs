def directory? path
  File.directory? path
end

ref = ENV['REF'] or raise "Please set a REF env variable, e.g. `env REF=v0.8.0 rake doc`\n\n"

task :setup do
  directory? 'opal' or sh 'git clone https://github.com/opal/opal.git opal'
  directory? 'gh-pages' or sh 'git clone git@github.com:opal/docs.git gh-pages --reference . -b master'
  cd 'opal' do
    sh "git reset --hard"
    sh "git clean -fx"
    sh "git checkout #{ref}"
  end

  cd 'gh-pages' do
    sh "git reset --hard"
    sh "git clean -fx"
    sh "git checkout gh-pages"
  end
end

task :doc => :setup do
  components = %w[corelib stdlib lib]
  base_dir   = "gh-pages/#{ref}"
  base_title = "Opal #{ref}"

  # Still need to decide how to format the runtime, for now let's just put it
  # in a markdown file and render it as it is.
  # Below some possible alternative implementations with DOCCO/GROC/DOXX.
  path = 'opal/opal/corelib/runtime.js'
  File.write "opal/opal/corelib/runtime.js.md", "# Opal Runtime:\n\n```js\n#{File.read path}\n```\n"

  components.each do |component|
    target = case component
             when 'corelib' then 'opal/opal'
             when 'stdlib'  then 'opal/stdlib'
             when 'lib'     then 'opal/lib'
             end

    sh %{
      sdoc
      --format sdoc
      --github
      --output #{base_dir}/#{component}
      --title "#{base_title} · #{component}"
      --hyperlink-all
      #{target}
    }.gsub(/\n */, " ").strip

  end

  # DOCCO/GROC
  # path = 'opal/opal/corelib/runtime.js'
  # contents = File.read path
  # normalized_contents = contents.gsub(%r{^(\s)*(?m:/\*.*?\*/ *$)}) do |match|
  #   lines = match.strip.split("\n")
  #   leading = lines.first.scan(/^ */).first + '// '
  #   normalized = lines.map do |line|
  #     line.sub(%r{^ *(?:/\*+|\* +|\*/|(?=[\S]|$))}, leading)
  #   end.compact.join("\n")
  #   "\n"+normalized
  # end
  # File.write path, normalized_contents
  # puts normalized_contents
  # # sh "groc --root opal/opal/corelib --output #{base_dir} runtime.js"
  # sh "docco --output #{base_dir} opal/opal/corelib/runtime.js"
  # File.write path, contents
  #
  # DOXX
  # command = "doxx --template #{doc_repo.join('doxx-templates/opal.jade')} "\
  #           "--source opal/corelib --target #{doc_base}/#{git}/#{name} "\
  #           "--title \"Opal runtime.js Documentation\" --readme opal/README.md"
  # puts command; system command or $stderr.puts "Please install doxx with: npm install"


  html_title = "#{base_title} API Documentation Index"
  File.write "#{base_dir}/index.html", <<-HTML.gsub(/^  /, '')
  <!doctype html>
  <html>
    <head>
      <title>#{html_title}</title>
      <style>body {font-family: sans-serif;}</style>
    </head>
    <body>
      <h1>#{html_title}</h1>
      <ul>
        #{components.map {|c| "<li><a href='./#{c}/index.html'>#{c}</a></li>"}.join}
      </ul>
    </body>
  </html>
  HTML
end


