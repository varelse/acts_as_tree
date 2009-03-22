module ActiveRecord
  module Acts
    module Tree
      
      class AATreeNode 
        attr_accessor :children, :value
        
        def initialize(value = nil, child_nodes = [])
          @value = value
          @children = child_nodes
        end
        
        def self.build_by_root_model_instance(root_model_instance, options = {})
          opts= {:depth => nil, :conditions => {}}
          opts.update(options);
          rmi = root_model_instance
          tree = new(root_model_instance)
          if not opts[:depth] or opts[:depth] > 1
            new_depth = (opts[:depth] ? opts[:depth] - 1 : nil)
            rmi.children(:conditions => opts[:conditions]).each do |child_mi|
              tree.children << build_by_root_model_instance(child_mi, opts.update({:depth => new_depth}))
            end
          end
          tree
        end
        
        def self.build_by_model_class(model, options = {})
          opts = {:depth => nil, :conditions => {}}
          opts.update(options);
          if not opts[:depth] or opts[:depth] > 1
            new_depth = (opts[:depth] ? opts[:depth] - 1 : nil)
            #root_model_instances
            root_mis = model.main_roots(:conditions => opts[:conditions])
            return build_by_root_model_instance(root_mis.first, opts) if root_mis.size == 1
            tree = new
            root_mis.each do |root_mi|
              tree.children << build_by_root_model_instance(root_mi, opts.update({:depth => new_depth}))
            end
          end
          tree
        end
        
        def each_post_order
          post_order.each {|value, level| yield(value, level) if value}
        end
        
        # Zwraca tablicę par [value, level] w porządku postfixowym
        def post_order(level = 0)
          array = [[self.value, level]]
          children.each {|child| array += child.post_order(level + 1)}
          array
        end
         
      end
      
    end
  end
end  
