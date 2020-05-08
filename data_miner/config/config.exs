use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :error_log}],
  format: "[$level] $message\n"

config :logger, :error_log,
  path: "./tmp/info.log",
  level: :debug
