defmodule Malarkey.Media do
  @moduledoc """
  Context for handling media uploads to the local filesystem.
  """

  @upload_dir "priv/static/uploads"

  @doc """
  Uploads a file to the local filesystem and returns the public URL.
  """
  def upload_file(file_path, content_type, user_id) do
    file_name = generate_filename(file_path, user_id)
    dest_path = Path.join(@upload_dir, file_name)
    File.mkdir_p!(Path.dirname(dest_path))
    case File.cp(file_path, dest_path) do
      :ok -> {:ok, get_public_url(file_name)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Uploads binary data (from paste) to the local filesystem.
  """
  def upload_binary(binary, content_type, user_id, extension \\ ".png") do
    file_name = generate_binary_filename(user_id, extension)
    dest_path = Path.join(@upload_dir, file_name)
    File.mkdir_p!(Path.dirname(dest_path))
    case File.write(dest_path, binary) do
      :ok -> {:ok, get_public_url(file_name)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Determines media type from content type or URL.
  """
  def get_media_type(content_type) when is_binary(content_type) do
    cond do
      String.starts_with?(content_type, "image/") -> "image"
      String.starts_with?(content_type, "video/") -> "video"
      true -> "unknown"
    end
  end

  def get_media_type(_), do: "unknown"

  @doc """
  Validates file size (10MB for images, 50MB for videos).
  """
  def validate_file_size(size, type) do
    max_size = case type do
      "image" -> 10 * 1024 * 1024  # 10MB
      "video" -> 50 * 1024 * 1024  # 50MB
      _ -> 10 * 1024 * 1024
    end

    if size <= max_size do
      :ok
    else
      {:error, "File too large. Maximum size is #{format_bytes(max_size)}"}
    end
  end

  # Private functions

  defp generate_filename(file_path, user_id) do
    extension = Path.extname(file_path)
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
    "#{user_id}/#{timestamp}_#{random}#{extension}"
  end

  defp generate_binary_filename(user_id, extension) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
    "#{user_id}/#{timestamp}_#{random}#{extension}"
  end

  defp get_public_url(file_name) do
    "/uploads/#{file_name}"
  end

  defp format_bytes(bytes) do
    cond do
      bytes >= 1024 * 1024 -> "#{div(bytes, 1024 * 1024)}MB"
      bytes >= 1024 -> "#{div(bytes, 1024)}KB"
      true -> "#{bytes}B"
    end
  end
end
