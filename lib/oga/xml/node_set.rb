module Oga
  module XML
    ##
    # The NodeSet class contains a set of {Oga::XML::Node} instances that can
    # be queried and modified. Optionally NodeSet instances can take ownership
    # of a node (besides just containing it). This allows the nodes to query
    # their previous and next elements.
    #
    # There are two types of sets:
    #
    # 1. Regular node sets
    # 2. Owned node sets
    #
    # Both behave similar to Ruby's Array class. The difference between an
    # owned and regular node set is that an owned set modifies nodes that are
    # added or removed by certain operations. For example, when a node is added
    # to an owned set the `node_set` attribute of said node points to the set
    # it was just added to.
    #
    # Owned node sets are used when building a DOM tree with
    # {Oga::XML::Parser}. By taking ownership of nodes in a set Oga makes it
    # possible to use these sets as following:
    #
    #     document = Oga::XML::Document.new
    #     element  = Oga::XML::Element.new
    #
    #     document.children << element
    #
    #     element.node_set == document.children # => true
    #
    # If ownership was not handled then you'd have to manually set the
    # `element` variable's `node_set` attribute after pushing it into a set.
    #
    # @!attribute [rw] owner
    #  @return [Oga::XML::Node]
    #
    class NodeSet
      include Enumerable

      attr_accessor :owner

      ##
      # @param [Array] nodes The nodes to add to the set.
      # @param [Oga::XML::NodeSet] owner The owner of the set.
      #
      def initialize(nodes = [], owner = nil)
        @nodes = nodes
        @owner = owner

        @nodes.each { |node| take_ownership(node) }
      end

      ##
      # Yields the supplied block for every node.
      #
      # @yieldparam [Oga::XML::Node]
      #
      def each
        @nodes.each { |node| yield node }
      end

      ##
      # Returns the last node in the set.
      #
      # @return [Oga::XML::Node]
      #
      def last
        return @nodes[-1]
      end

      ##
      # Returns `true` if the set is empty.
      #
      # @return [TrueClass|FalseClass]
      #
      def empty?
        return @nodes.empty?
      end

      ##
      # Returns the amount of nodes in the set.
      #
      # @return [Fixnum]
      #
      def length
        return @nodes.length
      end

      alias_method :count, :length
      alias_method :size, :length

      ##
      # Returns the index of the given node.
      #
      # @param [Oga::XML::Node] node
      # @return [Fixnum]
      #
      def index(node)
        return @nodes.index(node)
      end

      ##
      # Pushes the node at the end of the set.
      #
      # @param [Oga::XML::Node] node
      #
      def push(node)
        @nodes << node

        take_ownership(node)
      end

      alias_method :<<, :push

      ##
      # Pushes the node at the start of the set.
      #
      # @param [Oga::XML::Node] node
      #
      def unshift(node)
        @nodes.unshift(node)

        take_ownership(node)
      end

      ##
      # Shifts a node from the start of the set.
      #
      # @return [Oga::XML::Node]
      #
      def shift
        node = @nodes.shift

        remove_ownership(node)

        return node
      end

      ##
      # Pops a node from the end of the set.
      #
      # @return [Oga::XML::Node]
      #
      def pop
        node = @nodes.pop

        remove_ownership(node)

        return node
      end

      ##
      # Returns the node for the given index.
      #
      # @param [Fixnum] index
      # @return [Oga::XML::Node]
      #
      def [](index)
        return @nodes[index]
      end

      ##
      # Removes the current nodes from their owning set. The nodes are *not*
      # removed from the current set.
      #
      # This method is intended to remove nodes from an XML document/node.
      #
      def remove
        sets = []

        # First we gather all the sets to remove nodse from, then we remove the
        # actual nodes. This is done as you can not reliably remove elements
        # from an Array while iterating on that same Array.
        @nodes.each do |node|
          if node.node_set
            sets << node.node_set

            node.node_set = nil
          end
        end

        sets.each do |set|
          @nodes.each { |node| set.delete(node) }
        end
      end

      ##
      # Removes a node from the current set only.
      #
      def delete(node)
        removed = @nodes.delete(node)

        remove_ownership(removed) if removed

        return removed
      end

      ##
      # Returns the values of the given attribute.
      #
      # @param [String|Symbol] name The name of the attribute.
      # @return [Array]
      #
      def attribute(name)
        values = []

        @nodes.each do |node|
          if node.respond_to?(:attribute)
            values << node.attribute(name)
          end
        end

        return values
      end

      alias_method :attr, :attribute

      ##
      # Returns the text of all nodes in the set.
      #
      # @return [String]
      #
      def text
        text = ''

        @nodes.each do |node|
          if node.respond_to?(:text)
            text << node.text
          end
        end

        return text
      end

      private

      ##
      # Takes ownership of the given node. This only occurs when the current
      # set has an owner.
      #
      # @param [Oga::XML::Node] node
      #
      def take_ownership(node)
        node.node_set = self if owner
      end

      ##
      # Removes ownership of the node if it belongs to the current set.
      #
      # @param [Oga::XML::Node] node
      #
      def remove_ownership(node)
        node.node_set = nil if node.node_set == self
      end
    end # NodeSet
  end # XML
end # Oga