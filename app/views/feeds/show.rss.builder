xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "RailsBlog"
    xml.description "Latest published articles"
    xml.link root_url
    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.excerpt.presence || truncate(post.body, length: 500)
        xml.pubDate post.published_at.rfc2822
        xml.link post_url(post)
        xml.guid post_url(post)
      end
    end
  end
end
