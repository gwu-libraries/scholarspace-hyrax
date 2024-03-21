module Scholarspace
  module YearIndexer
    def self.get_four_digit_year(input_arr)
      result = input_arr.detect { |value| value.length == 4 && value.to_i.to_s == value }      
      if result != nil
        return result.to_i
      else
        return nil
      end
    end
  end
end