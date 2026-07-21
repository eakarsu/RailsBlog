require "application_system_test_case"

class PublishingJourneyTest < ApplicationSystemTestCase
  test "author submits and independent editor publishes an article" do
    author = create_user(email: "author@example.test", name: "Avery Author")
    editor = create_user(role: "editor", email: "editor@example.test", name: "Elliot Editor")

    visit login_path
    fill_in "Email", with: author.email
    fill_in "Password", with: "correct horse battery staple"
    click_button "Sign in"
    click_link "New draft"
    fill_in "Title", with: "Community reporting"
    fill_in "Body", with: "A verified and accessible public-interest article."
    click_button "Create Post"
    click_button "Submit for review"
    click_button "Sign out"

    visit login_path
    fill_in "Email", with: editor.email
    fill_in "Password", with: "correct horse battery staple"
    click_button "Sign in"
    visit post_path(Post.last)
    click_button "Publish"
    assert_text "Article moved to published"
    assert_text "Community reporting"
  end
end
