module WillPaginate::ViewHelpers
  class LinkRenderer

    private

    def html_container(html)
      %Q|<div class="page_browsing_controls"><span class="per_page_selector">
    Per Page: <select name="per_page" id="per_page">
    <option value="10">10</option>
    <option value="25">25</option>
    <option value="50">50</option>
    <option value="100">100</option>
    <option value="250">250</option>
    <option value="500">500</option>
    </select>
    </span>
      #{tag(:div, html, container_attributes)}</div>|
    end

  end
end
