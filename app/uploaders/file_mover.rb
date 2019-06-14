# frozen_string_literal: true

class FileMover
  include Gitlab::Utils::StrongMemoize

  attr_reader :secret, :file_name, :model, :update_field

  def initialize(file_path, model, update_field = :description)
    @secret = File.split(File.dirname(file_path)).last
    @file_name = File.basename(file_path)
    @model = model
    @update_field = update_field
  end

  def execute
    temp_file_uploader.retrieve_from_store!(file_name)

    return unless valid?

    uploader.retrieve_from_store!(file_name)

    move

    if update_markdown
      uploader.record_upload
      uploader.schedule_background_upload
    end
  end

  private

  def valid?
    if temp_file_uploader.file_storage?
      Pathname.new(temp_file_path).realpath.to_path.start_with?(
        (Pathname(temp_file_uploader.root) + temp_file_uploader.base_dir).to_path
      )
    else
      temp_file_uploader.exists?
    end
  end

  def move
    if temp_file_uploader.file_storage?
      FileUtils.mkdir_p(File.dirname(file_path))
      FileUtils.move(temp_file_path, file_path)
    else
      uploader.copy_file(temp_file_uploader.file)
    end
  end

  def update_markdown
    updated_text = model.read_attribute(update_field)
                        .gsub(temp_file_uploader.markdown_link, uploader.markdown_link)
    model.update_attribute(update_field, updated_text)
  rescue
    revert
    false
  end

  def temp_file_path
    strong_memoize(:temp_file_path) { temp_file_uploader.file.path }
  end

  def file_path
    strong_memoize(:file_path) { uploader.file.path }
  end

  def uploader
    @uploader ||= PersonalFileUploader.new(model, secret: secret)
  end

  def temp_file_uploader
    @temp_file_uploader ||= PersonalFileUploader.new(nil, secret: secret)
  end

  def revert
    Rails.logger.warn("Markdown not updated, file move reverted for #{model}")

    FileUtils.move(file_path, temp_file_path)
  end
end
