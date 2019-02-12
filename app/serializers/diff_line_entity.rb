# frozen_string_literal: true

class DiffLineEntity < Grape::Entity
  expose :line_code
  expose :type
  expose :old_line
  expose :new_line
  expose :text
  expose :meta_positions, as: :meta_data
  expose :added?, as: :added
  expose :removed?, as: :removed
  expose :unchanged?, as: :unchanged

  expose :rich_text do |line|
    ERB::Util.html_escape(line.rich_text || line.text)
  end

  expose :suggestible?, as: :can_receive_suggestion
end
