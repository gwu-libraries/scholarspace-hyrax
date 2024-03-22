module Scholarspace
  module YearIndexer
    def self.get_four_digit_year(input_arr)
      result_arr = input_arr.select { |value| value.length == 4 && value.to_i.to_s == value }
      numeric_results = result_arr.map { |value| value.to_i } 
      min_result = numeric_results.min()

      if min_result != nil
        return min_result
      else
        return nil
      end 
    end
  end
end