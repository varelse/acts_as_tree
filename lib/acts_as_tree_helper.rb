module ActsAsTreeHelper
  
  def show_tree(tree, options = {}, &block)
    opts = {:class => nil, :id => nil, :foldable => false}
    opts.update(options)
    result = opening_ul_for_tree(0, opts)
    prev_level = 0
    tree.each_post_order do |obj, level|
      level_diff = prev_level - level
      element = opening_li_for_tree(obj, opts) + capture(obj, &block) + "</li>\n"
      if level_diff == 0
        result += element
      elsif level_diff < 0  
        result += (opening_ul_for_tree(level, opts) + element)
      else
        result += ("</ul>"*level_diff + element)
      end
      prev_level = level
    end
    concat result + "</ul>"*(prev_level + 1)
  end
  
  
  protected
  
  def opening_ul_for_tree(level, options, obj = nil)
    classes, id = [[], nil]
    if level == 0
      classes << 'tree'
      classes << 'foldable' if options[:foldable]
      classes << options[:class] if options[:class]
      id = options[:id] if options[:id]
    end
    classes << "level_#{level}"
    html_opening_tag('ul', :classes => classes, :id => id)
  end
  
  
  def opening_li_for_tree(obj, options = {}, level = nil)
    opts = {}
    opts[:style] = "display: none;" unless obj
    html_opening_tag('li', opts)
  end
  
  
  def html_opening_tag(tag_name, options = {})
    opts = {:classes => [], :id => nil}
    opts.update(options)
    classes, id = [opts.delete(:classes), opts.delete(:id)]
    result = "<" + tag_name
    result += (' class="' + (classes.sum {|c| ' ' + c}).strip + '"') unless classes.empty?
    result += (' id="' + id + '"') if id
    opts.each do |key, value|
      result += (' ' + key + '="' + value + '"')
    end
    result += ">"
    result
  end
  
end