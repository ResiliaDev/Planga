defmodule FixAsset do
  def update_file(filename, old, new) do
    File.stream!(filename)
    |> Enum.map(&String.replace(&1, old, new))
    |> Stream.into(File.stream!(filename))
    |> Stream.run
  end
end

FixAsset.update_file(
  "node_modules/semantic-ui-css/semantic.min.css",
  "url(themes/default/assets/fonts",
  "url(../fonts"
)
