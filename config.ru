root = Pathname("#{__dir__}/gh-pages")
use Rack::Static, root: root.to_s, index: 'index.html'
run -> env {
  file = root.join(env['PATH_INFO'][1..-1])
  file.exist? ? [200, {}, file.open('r')] : [404,{},[]]
}
