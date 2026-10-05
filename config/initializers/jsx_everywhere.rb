default_blacklist = React::JSX::BabelTransformer::DEFAULT_TRANSFORM_OPTIONS.fetch :blacklist

# Leave async/await native; the regenerator output needs a runtime we don't ship.
Rails.application.config.react.jsx_transform_options = {
  blacklist: default_blacklist + ['regenerator'],
}

Sprockets.register_transformer 'application/javascript', 'application/javascript', React::JSX::Processor
