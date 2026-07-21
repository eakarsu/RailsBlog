require "test_helper"

class ImporterTest < ActiveSupport::TestCase
  test "validates first then imports only drafts with taxonomy" do
    editor = create_user(role: "editor")
    json = { schema_version: 1, articles: [{ title: "Imported article", body: "Portable content", categories: ["News"], tags: ["Rails"] }] }.to_json
    validation = Publishing::Importer.call(json: json, actor: editor, dry_run: true)
    assert_equal "validated", validation.status
    assert_no_difference("Post.count") { validation }
    assert_difference("Post.count", 1) { Publishing::Importer.call(json: json, actor: editor, dry_run: false) }
    assert_equal "draft", Post.last.status
    assert_equal ["News"], Post.last.categories.pluck(:name)
  end

  test "rejects malformed and unauthorized imports" do
    assert_raises(Publishing::Importer::InvalidPayload) { Publishing::Importer.call(json: "not json", actor: create_user(role: "editor")) }
    assert_raises(Publishing::Importer::InvalidPayload) do
      Publishing::Importer.call(json: { schema_version: 1, articles: [] }.to_json, actor: create_user)
    end
    editor = create_user(role: "editor")
    invalid_terms = { schema_version: 1, articles: [{ title: "Valid title", body: "Valid body", tags: "not-an-array" }] }.to_json
    run = Publishing::Importer.call(json: invalid_terms, actor: editor)
    assert_equal "rejected", run.status
    assert_includes run.reported_errors.join, "tags must be an array"
  end
end
