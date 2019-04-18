require "spec_helper"

describe "User edits issue", :js do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(edit_project_issue_path(project, issue))
  end

  it "previews content" do
    form = first(".gfm-form")

    page.within(form) do
      fill_in("Description", with: "Bug fixed :smile:")
      click_button("Preview")
    end

    expect(form).to have_button("Write")
  end
end
