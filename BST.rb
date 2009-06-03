module BST
  class BSTNode < Array
    alias :left :first
    alias :right :last
  end
  
  class BSTTree
    def initialize(ary)
      @tree = []
      ary.each { |elem| insert(elem) }
    end
  
    def insert(elem)
      if @tree == [] 
        @tree << elem
      else
        
      end
    end

end