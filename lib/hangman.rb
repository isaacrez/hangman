# TASKS
# - Get the object to properly parse into JSON

require 'set'

class GameManager
  @@current_game
  def self.current_game
    return @@current_game
  end

  def self.run
    puts "Welcome to Hangman!"
    loop do

      puts "- 'START': Starts a new game"
      puts "- 'SAVE [FILENAME]': Save your current game"
      puts "- 'SAVE': View all old save files"
      puts "- 'LOAD [FILENAME]': Load a saved game"
      puts "- 'DEL [FILENAME]': Delete a saved game"
      puts "- 'QUIT': Exit the current game or program."
      print "> "

      request = gets.chomp.downcase
      if request == 'start'
        @@current_game = Hangman.new
        @@current_game.start

      elsif request == 'save'
        puts "Here are the existing save files:"
        GameManager.show_saves
        print "\n"

      elsif request.start_with? 'save'
        print "You can't save yet! There's no game.\n\n"
      
      elsif request.start_with? 'load'
        filename = request.split(' ')[1]
        load filename
      
      elsif request.start_with? 'del'
        filename = request.split(' ')[1]
        delete filename

      elsif request == 'quit'
        break

      else
        print "I didn't understand that -- try again?\n\n"
      end
    end
  end

  def self.show_saves
    GameManager.create_save_dir
    save_names =  Dir.children("saves")
    unless save_names.length == 0
      print " - " + save_names.join("\n - ") + "\n"
    else
      print "No save data found\n\n"
    end
  end

  def self.save(filename)
    GameManager.create_save_dir
    File.open("saves/" + filename, "w") do |file|
      Marshal.dump(@@current_game, file)
    end
  end

  def self.load(filename)
    GameManager.create_save_dir
    File.open("saves/" + filename, "r") do |file|
      @@current_game = Marshal.load(file.read)
      @@current_game.take_guesses
    end
  end

  def self.delete(filename)
    GameManager.create_save_dir
    path = "save/" + filename
    Dir.delete(path) if Dir.exist? path
  end

  def self.create_save_dir
    Dir.mkdir("saves") unless Dir.exists? "saves"
  end
end

class Hangman
  def initialize
    @good_guesses = Set[]
    @all_guesses = Set[]
    @tries_remaining = 5
    @completed = false
  end

  def start
    random_word
    take_guesses
  end

  def random_word
    dictionary = File.read('dictionary.txt').split("\r\n")
    dictionary.filter! {|word| 5 < word.length && word.length < 12}
    index = rand(dictionary.length)
    @word = dictionary[index]
  end

  def take_guesses
    puts "Try to guess it..."

    until @completed || @tries_remaining == 0
      display_word = get_displayed_word
      break if display_word == @word

      puts "Current word: #{display_word}, you have #{@tries_remaining} guesses left."
      print "> "
      guess = gets.chomp.downcase

      if guess.start_with? 'save'
        save guess
      elsif guess == 'quit'
        lose
      elsif validate_guess guess
        process_guess guess  
      end
    end

    @tries_remaining == 0 ? lose : win
  end

  def save(line)
    filename = line.split(' ')[1]
    print "Saved game to #{filename}\n\n"
    GameManager.save(filename)
  end

  def win
    @completed = true
    print "That spells #{@word.upcase}!\nCongratulations, you win!\n\n"
  end

  def lose
    @completed = true
    print "Boo, you lose - the word was #{@word}!\n\n"
  end

  def process_guess(guess)
    unless @all_guesses.include? guess
      @all_guesses.add(guess)
      if @word.include? guess
        puts "Good guess!\n"
        @good_guesses.add(guess)
      else
        puts "Ouch! That letter wasn't there\n"
        @tries_remaining -= 1
      end
    else
      puts "You already guessed that!"
    end
  end

  def validate_guess(guess)
    case guess.length
    when 1
      if 'a' <= guess && guess <= 'z'
        return true
      else
        puts "Please keep it to the alphabet!"
      end
    when 0
      puts "C'mon, guess something!"
    else
      puts "Too long! Guess ONE character!"
    end
    return false
  end

  def get_displayed_word
    display_array = []
    @word.downcase.each_char do |char|
      if @good_guesses.include? char
        display_array.append(char)
      else
        display_array.append('_')
      end
    end

    display_word = display_array.join()
    @completed = true if display_word == @word
    return display_word
  end
end

GameManager.run