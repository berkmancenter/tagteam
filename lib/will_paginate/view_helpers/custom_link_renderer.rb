# frozen_string_literal: true
module WillPaginate::ViewHelpers
  class LinkRenderer
    private

    def html_container(html)
      %(<div class="page_browsing_controls">#{tag(:div, html, container_attributes)}
      <span class="per_page_selector_container">
    Per Page: <select name="per_page" class="per_page_selector">
    <option value="10" #{'selected="selected"' if @collection.per_page == 10}>10</option>
    <option value="25" #{'selected="selected"' if @collection.per_page == 25}>25</option>
    <option value="50" #{'selected="selected"' if @collection.per_page == 50}>50</option>
    <option value="100" #{'selected="selected"' if @collection.per_page == 100}>100</option>
    <option value="250" #{'selected="selected"' if @collection.per_page == 250}>250</option>
    <option value="500" #{'selected="selected"' if @collection.per_page == 500}>500</option>
    </select>
    </span>
      </div>)
    end
  end
end
