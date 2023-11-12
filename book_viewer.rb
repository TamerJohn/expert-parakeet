require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

helpers do
  def slugify(text)
    text.downcase.gsub(/\s+/, "-").gsub(/[^\w-]/)
  end

  def in_paragraphs(text)
    # text = text.split("\n\n")
    # text.prepend("<p>")
    # text << "</p>"

    # text.join("</p>\n<p>")

    text.split("\n\n").map.with_index do |paragraph, idx|
      "<p id=\"#{idx + 1}\">#{paragraph}</p>\n"
    end.join("")
  end

  def generate_query_paragraph(chapter_number, paragraph_num, query)
    chapter_text = File.read("data/chp#{chapter_number}.txt")
    chapter_text.split("\n\n")[paragraph_num-1].gsub(query, "<strong>#{query}</strong>")
  end
end

before do
   @contents = File.readlines("data/toc.txt")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapter/:number" do
  chapter_number = params[:number].to_i
  redirect "/" unless (1..@contents.size).include?(chapter_number)

  @chapter_name = @contents[chapter_number-1]
  @chapter_text = File.read("data/chp#{chapter_number}.txt")
  @title = "Chapter #{chapter_number}: #{@chapter_name}"

  erb :chapter
end

get "/show/:name" do
  params["name"]
end

not_found do
  redirect "/"
end

get "/search" do
  def append_results(arr, file_name, paragraph_num)
    number = /\d+/.match(file_name).to_s
    name = @contents[number.to_i-1]

    arr << {chapter_number: number, chapter_name: name, pargraph_nums: [paragraph_num]}
  end

  def generate_results()
    @results = []

    current_result_index = 0
    next_result_index = nil

    Dir.each_child("./data") do |child|
      text = File.read("./data/#{child}")
      current_result_index = next_result_index if next_result_index

      appended = false
      text.split("\n\n").each_with_index do |paragraph, paragraph_num|
        if paragraph.include?(@query) && !appended
          append_results(@results, child, (paragraph_num + 1))
          appended = true
          next_result_index = current_result_index + 1

        elsif paragraph.include?(@query)
          @results[current_result_index][:pargraph_nums] << (paragraph_num + 1)
        end
      end
    end
  end

  @query = params[:query]
  generate_results if @query

  def result_found?
    @results && !@results.empty?
  end

  erb :search
end

