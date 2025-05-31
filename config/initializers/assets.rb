Rails.application.config.assets.precompile += [ 'gallery.js', 'share.js', 'index.css' ]
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
Rails.application.config.assets.precompile += %w(*.svg *eot *.woff *.ttf *.woff2)
