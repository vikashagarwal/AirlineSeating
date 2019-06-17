require 'json'

class SeatingArrangement
  attr_accessor :booking_exceed, :max_seats, :seats_len, :traveller_count, :message

  def initialize(*args)
    @message = input_check(args)
    if @message.nil?
      @max_seats = @input_seats.inject(0) { |sum, x| sum += x[0] * x[1] }# finding the max seat capacity
      @seats_len = @max_seats.to_s.size + 1
      @booking_exceed = true if @max_seats < @traveller_count
      @max_columns = @input_seats.map(&:last).max # finding the max number of columns in the seating arrangement
      @travellers_allocated = 0 # keeping count of travellers allocated
    end
  end

  def assign_seat
    prepare_seats_arrangement
    aisle_seats
    window_seats
    center_seats
  end

  def input_check(args)
    return "Please provide input: A 2D array and the Number of travellers" if args.flatten.map(&:strip).reject(&:empty?).empty?
    return "Please provide a 2D array as the first argument" if args.flatten[0].strip.empty?
    return "Please provide the Number of travellers as the second argument" if args.flatten[1].nil? || args.flatten[1].strip.empty?
    begin
      @input_seats = JSON.parse(args[0])
    rescue
      return "The first argument is invalid! Please input a 2D array."
    end
    return "The given array is not in 2D format!" unless @input_seats.all? { |x| x.is_a?(Array) }
    return "All the sub-arrays of the given 2D array are not of [x,y] format!" unless @input_seats.all? { |x| x.size == 2 }
    return "The sub-arrays are in [x,y] format but 'x' and 'y' should be NON-ZERO values!" if @input_seats.any? { |x| x.any?(0) }
    begin
      @traveller_count = args[1].to_i
    rescue
      return "The second argument is invalid! Please enter the number of travellers."
    end
    return "The second argument should be a positive integer" unless @traveller_count.is_a?(Integer)
  end

  private

  def prepare_seats_arrangement
    @available_seats = @input_seats.each_with_object([]).with_index do |(arr, seats), index|
      seats << (1..arr[1]).map { |x| Array.new(arr[0]) { 'N' } }
    end # making the seat arrangement having based on different sections
    @sorted_seats = (1..@max_columns).each_with_object([]).with_index do |(x, arr), index|
      arr << @available_seats.map { |x| x[index] }
    end # arranging the seats available based on rows
  end

  def aisle_seats
    @aisle_seats = @sorted_seats.each_with_object([]) do |elem_array, res_array|
      res_array << if elem_array.nil?
        nil
      else
        elem_array.each_with_object([]).with_index do |(basic_elem_array, update_arr), index|
          update_arr << if basic_elem_array.nil?
            nil
          else
            if index == 0 # For Allocating the first section of rows
              @travellers_allocated += 1
              basic_elem_array[-1] = seat_number('A')
            elsif index == elem_array.size - 1 # For Allocating the last section of rows
              if basic_elem_array.size != 1 # If there is more than 1 seat in that row else it will be window seat
                @travellers_allocated += 1
                basic_elem_array[0] = seat_number('A')
              end
            else
              @travellers_allocated += 1
              basic_elem_array[0] = seat_number('A')
              if basic_elem_array.size != 1
                @travellers_allocated += 1
                basic_elem_array[-1] = seat_number('A')
              end
            end
            basic_elem_array
          end
        end
      end
    end
  end

  def window_seats
    @window_seats = @aisle_seats.each_with_object([]) do |elem_array, res_array|
      res_array << if elem_array.nil?
        nil
      else
        elem_array.each_with_object([]).with_index do |(basic_elem_array, update_arr), index|
          update_arr << if basic_elem_array.nil?
            nil
          else
            if index == 0 # For Allocating the first section of rows
              @travellers_allocated += 1
              basic_elem_array[0] = seat_number('W')
            elsif index == elem_array.size - 1 # For Allocating the last section of rows
              @travellers_allocated += 1
              basic_elem_array[-1] = seat_number('W')
            end
            basic_elem_array
          end
        end
      end
    end
  end

  def center_seats
    @center_seats = @window_seats.each_with_object([]) do |elem_array, res_array|
      res_array << if elem_array.nil?
        nil
      else
        elem_array.each_with_object([]).with_index do |(basic_elem_array, update_arr), index|
          update_arr << if basic_elem_array.nil?
            nil
          else
            if basic_elem_array.size > 2
              (1..basic_elem_array.size - 2).each do |x|
                @travellers_allocated += 1
                basic_elem_array[x] = seat_number('C')
              end
            end
            basic_elem_array
          end
        end
      end
    end
  end

  def seat_number seat_type
    @travellers_allocated <= @traveller_count ? @travellers_allocated.to_s.rjust(@seats_len, "0") : (('-' * (@seats_len - 2)) + seat_type + '-')
  end
end

puts "Enter 2D array: "
array_ip = gets.chomp
puts "Enter the number of travellers: "
pass_count = gets.chomp
airline_seating = SeatingArrangement.new(array_ip, pass_count)

if airline_seating.message.nil?
  puts "Sorry! We don't have enough seats to occupy #{airline_seating.traveller_count} travellers.\
   Only #{airline_seating.max_seats} seats are available!" if airline_seating.booking_exceed
  result = airline_seating.assign_seat
  result.each_with_index do |row, parent_index|
    row_formatted = ''
    row.each_with_index do |arr, index|
      print_value = arr.inspect.gsub('[', '').gsub(']', '').gsub(',', '').gsub('"', '')
      print_value += ' | ' if index != row.size - 1

      if parent_index == 0
        instance_variable_set("@arr_length_#{index}", print_value.gsub(' | ', '').split(' ').length)
      else
        print_value = (('-' * airline_seating.seats_len) + ' ') * (instance_variable_get("@arr_length_#{index}").to_i) + ('| ') if print_value.strip == 'nil |'
      end
      row_formatted += print_value
    end
    puts "#{row_formatted}\n"
  end
else
  puts airline_seating.message
end
