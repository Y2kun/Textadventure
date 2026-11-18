# frozen_string_literal: true

class Enemy
  attr_accessor :health, :defense, :reward

  def attack(enemy)
    enemy.take_damage(@attack)
  end

  def take_damage(attack_damage)
    @health -= [0, (attack_damage - @defense)].max
  end

  def alive?
    @health.positive?
  end

  def to_s
    "#{self.class} health: #{@health} attack: #{@attack} defense: #{@defense}"
  end
end

class Wolf < Enemy
  def initialize
    @attack = 2
    @defense = 0
    @health = 4
    @reward = 2
  end
end

class Witch < Enemy
  def initialize
    @attack = 5
    @defense = 5
    @health = 5
    @reward = 5
  end
end

PLACES = {}

class Place
  attr_reader :id, :name, :goods, :next_places, :enemies

  def initialize(id, name, goods, next_places, enemies)
    @id = id
    @name = name
    @goods = goods
    @next_places = next_places
    @enemies = enemies
    PLACES[id] = self
  end

  def to_s
    @name
  end
end

Place.new('inn', 'Inn', %w[healing], %w[training_attack training_defense], nil)
Place.new('training_attack', 'Training grounds (Attack)', %w[attack], %w[inn plains1], nil)
Place.new('training_defense', 'Training grounds (Defense)', %w[defense], %w[inn plains1], nil)
Place.new('plains1', 'Plains1', nil, %w[training_attack training_defense plains2], [Wolf])
Place.new('plains2', 'Plains2', nil, %w[plains3], [Wolf])
Place.new('plains3', 'Plains3', nil, %w[plains2], [Wolf, Witch])

class Person
  attr_reader :name, :place, :gold, :defense, :health

  def initialize(name, place)
    @attack = 1
    @defense = 1
    @health = 4
    @max_health = 4
    @max_mana = 5
    @mana = 5
    @level = 1
    @experience = 0
    @gold = 5
    @name = name
    @place = place
  end

  def take_damage(attack_damage)
    @health -= [0, attack_damage - @defense].max
  end

  def attack(enemy)
    enemy.take_damage(@attack)
  end

  def heal
    price = 1
    return unless @mana >= price

    @mana -= price
    @health = @max_health
  end

  def alive?
    @health.positive?
  end

  # def go_next
  #   next_places = @place.next_places
  #   if next_places.empty?
  #     puts 'you fell into the void'
  #     exit
  #   else
  #     @place = PLACES[next_places.sample]
  #   end
  # end

  def go_next
    next_places = @place.next_places

    destinations = next_places.map do |place_id|
      PLACES[place_id]
    end

    destination = select_option(
      'Where would you like to go?',
      destinations
    )

    @place = destination

    puts "You travel to #{@place.name}."
  end

  def buy_healing
    price = 1
    return unless @gold >= price

    @gold -= price
    @health = @max_health
    @mana = @max_mana
    true
  end

  def buy_attack
    price = @attack * 4
    return unless @gold >= price

    @gold -= price
    @attack += 1
    true
  end

  def buy_defense
    price = @defense * 4
    return unless @gold >= price

    @gold -= price
    @defense += 1
    true
  end

  def earn_money(earned)
    raise ArgumentError, 'Amount must be a positive integer' unless earned.is_a?(Integer) && earned.positive?

    @gold += earned
    true
  end

  def to_s
    "health: #{@health} attack: #{@attack} defense: #{@defense}"
  end
end

def ask(question)
  puts question
  gets.strip
end

def select_option(question, options)
  loop do
    puts question

    options.each_with_index do |option, index|
      puts "#{index + 1}. #{option}"
    end

    choice = ask('Choose an option:')

    index = choice.to_i - 1

    return options[index] if index.between?(0, options.length - 1)

    puts 'Invalid choice. Please try again.'
  end
end

puts 'God:'
name = ask 'Choose your name'

you = Person.new(name, PLACES['inn'])

puts "Welcome to the world of Aetheria #{you.name}"
puts 'Your duty is to get strong and defeat nuk2Y'

loop do
  place = you.place
  puts "You are now in #{place.name}"

  if place.enemies
    enemy = place.enemies.sample.new

    while enemy.alive? && you.alive?
      puts "You have to defeat #{enemy}"
      puts "Your stats are #{you}"

      actions = %w[attack heal]
      choice = select_option('What would you like to do?', actions)
      case choice
      when 'attack'
        you.attack(enemy)
      when 'heal'
        you.heal
      else
        puts "I do not know what #{choice} is"
        next
      end

      if enemy.alive?
        enemy.attack(you)
      else
        puts "You defeated #{enemy}"

        you.earn_money enemy.reward
        puts "You are awarded #{enemy.reward} gold."
      end
    end

    unless you.alive?
      puts 'You have been defeated!'
      exit
    end

    you.go_next
  else
    actions = %w[go buy]
    actions.delete('buy') unless place.goods

    choice = select_option('What would you like to do?', actions)
    case choice
    when 'go'
      you.go_next
    when 'buy'
      puts "You can purchase #{you.place.goods} here"
      item = select_option('What would you like to buy?', place.goods)
      if you.respond_to?("buy_#{item}")
        if you.send("buy_#{item}")
          puts 'Thank you for buying'
          puts "You have #{you.gold} gold left"
        else
          puts 'You cannot afford this, go get me some gold!'
        end
      else
        puts "I don't know what you just said, please say it again."
      end
    else
      puts "I didn't understand you, you can choose 'go' or 'buy'"
    end
  end
  puts ''
end
