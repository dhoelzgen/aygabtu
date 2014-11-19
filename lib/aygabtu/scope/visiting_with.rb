module Aygabtu
  module Scope
    module VisitingWith
      def visiting_with(pass_data)
        passing = self.visiting_data.merge(pass_data)
        new_data = @data.dup.merge(visiting_data: passing)
        self.class.new(new_data)
      end

      def inspect_data
        super.merge(visiting_data: inspected_or_nil(@data[:visiting_data]))
      end

      def self.factory_method
        :visiting_with
      end
    end
  end
end
