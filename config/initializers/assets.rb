Rails.application.config.assets.precompile += [ 'gallery.js', 'share.js', 'index.css' ]
Rails.application.config.assets.paths << Rails.root.join('node_modules')
