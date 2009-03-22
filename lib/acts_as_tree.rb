# TODO
# Foldable, Dragable 
# jesli uzytkownik wybiera order column, to znaczy, ze nie powinnismy automatycznie jej wypelniac
# lepiej ulokowac i przemyslec tree_structure

require 'tree_structure'

module ActiveRecord
  module Acts
    module Tree      
      def self.included(base)
        base.extend(ClassMethods)
      end


      module ClassMethods
        def acts_as_tree(options = {})
          aatree_config = {:foreign_key => "parent_id", :order => nil}
          aatree_config.update(options) if options.is_a?(Hash)

          belongs_to :parent, :class_name => name, :foreign_key => aatree_config[:foreign_key]
          has_many :children, :class_name => name, :foreign_key => aatree_config[:foreign_key], :order => aatree_config[:order], :dependent => :destroy
          
          named_scope :main_roots, :conditions => {aatree_config[:foreign_key] => nil}, :order => aatree_config[:order]
          
          class_eval %Q{
            include ActiveRecord::Acts::Tree::InstanceMethods
            extend ActiveRecord::Acts::Tree::SingletonMethods
            
            def aatree_parent_id
              #{aatree_config[:foreign_key]}
            end
            
            def aatree_parent_id=(value)
              #{aatree_config[:foreign_key]} = value
            end
          }
                    
          if not aatree_config[:order].blank?    
            after_create_callback_chain.push(:aatree_update_order_column_after_create)
            class_eval %Q{
              include ActiveRecord::Acts::Tree::InstanceMethodsWithOrdering
              
              def aatree_ordering
                #{aatree_config[:order]}
              end

              def aatree_ordering_column
                "#{aatree_config[:order]}".to_sym
              end
            
              def aatree_ordering=(value)
                #{aatree_config[:order]} = value
              end
            }
          else  
            class_eval {
              def aatree_ordering_column 
                nil 
              end
            }
          end
          
        end
      end


      module SingletonMethods
        
        def root
          main_roots.size == 1 ? main_roots.first : nil
        end
        
        def for_select(options = {})
          opts = {:root_object => nil, :depth => nil, :conditions => {}, :tab_str => '--', :name_attr => 'name',
                  :empty_value => true}
          opts.update(options);
          for_sel = []
          for_sel << ['', nil] if opts[:empty_value]
          t = tree(opts)
          t.each_post_order do |obj, level|
            select_name = (level > 0 ? opts[:tab_str].to_s*level : "")
            select_name += obj.attributes[opts[:name_attr]]
            for_sel << [select_name, obj.id]
          end
          for_sel
        end
        
        def tree(options = {})
          opts = {:root_object => nil, :depth => nil, :conditions => {}}
          opts.update(options)
          raise "Tree depth needs to be nil or an integer bigger than 0" if opts[:depth] and opt[:depth] < 1
          if opts[:root_object]
            root_object = opts.delete(:root_object)
            AATreeNode.build_by_root_model_instance(root_object, options)
          else  
            AATreeNode.build_by_model_class(self, options)            
          end
        end
                           
      end



      module InstanceMethods
        # Returns list of ancestors, starting from parent until root.
        def ancestors
          node, nodes = self, []
          nodes << node = node.parent while node.parent
          nodes
        end

        # Returns the root node of the tree.
        def root
          node = self
          node = node.parent while node.parent
          node
        end
        
        def is_root?
          aatree_parent_id ? false : true
        end
        
        # Returns all siblings of the current node.
        def siblings
          self_and_siblings - [self]
        end

        # Returns all siblings and a reference to the current node.
        def self_and_siblings
          parent ? parent.children : self.class.main_roots
        end
      end
      
      
      module InstanceMethodsWithOrdering   
        
        def move_up_in_tree
          s = self_and_siblings
          i = s.index(self)
          return if i == s.size - 1
          to_swap = s[i + 1]
          aatree_swap_with(to_swap)
        end
        
        def move_down_in_tree
          s = self_and_siblings
          i = s.index(self)
          return if i == 0
          to_swap = s[i - 1]
          aatree_swap_with(to_swap)
        end
        
        private
        
        def aatree_update_order_column_after_create
          if not aatree_ordering
            update_attribute(aatree_ordering_column, id)
          end
        end
        
        def aatree_swap_with(to_swap)
          self.class.transaction do
            self.aatree_ordering, to_swap.aatree_ordering = [to_swap.aatree_ordering, self.aatree_ordering]
            self.save!
            to_swap.save!
          end
        end     
      end
      
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::Tree
end
