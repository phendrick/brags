require 'json'

module ArrayRefinement
  refine Array do
    def to_markdown
      collect do |link|
        "[#{link}](#{link})"
      end
    end
  end
end

module Bragr
  class Builder
    using ArrayRefinement

    def initialize(brags, title: "Achievements")
      @brags = brags
      @title = title
    end

    def to_markdown
      out = []

      out << "# #{@title}"
      @brags.each do |year, achievement_group|
        out << "## #{year}"

        grouped_by_label = achievement_group.each_with_object({}) do |(label, achievements), memo|
          key = label.capitalize

          if memo[key]
            memo[key] += achievements
          else
            memo[key] = achievements
          end
        end

        grouped_by_label.each do |label, achievements|
          out << "\n### #{label.capitalize}\n"

          achievements.each do |achievement|
            out << "#{achievement[:text]}\n"
            out << "* #{achievement[:links].to_markdown.join(', ')}\n" if achievement[:links].any?
          end
        end
      end

      out.join("\n")
    end
  end
end

# Usage...

# output = {"2024-02":{"impact":[{"text":"I did a thing","links":["github.com"]}],"communictation":[{"text":"I did a thing","links":["github.com"]}],"uncategorised":[{"text":"Test","links":[]},{"text":"Test","links":[]},{"text":"I did a thing","links":[]}],"hack days":[{"text":"I made a console tool","links":["freeagent.com"]}],"fun":[{"text":"I made a console tool","links":[]}],"Hack Days":[{"text":"I did a hack days","links":["github.com"]}]}}
# puts Bragr::Builder.new(output).to_markdown

file_contents = File.read("humble_brags.json")
brags_hash = JSON.parse(file_contents, symbolize_names: true)
bd = Bragr::Builder.new(brags_hash)

File.open('brag_doc.md', 'w') { |f| f.write bd.to_markdown }
