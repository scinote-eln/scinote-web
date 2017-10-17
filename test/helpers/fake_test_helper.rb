module FakeTestHelper

  # Generates random CSV file - used for testing purposes
  def generate_csvfile
    file = Tempfile.open("test", Rails.root.join("tmp"))
    begin
      (1..10).each do |i|
        (1..10).each do |k|
          file.write(rand(50..100).to_s + ",")
        end
        file.write("\n")
      end
    ensure
      file.close
    end
    file.open
  end

  # Generates File of size size_in_mb and returns fd
  def generate_file(size_in_mb)
    require 'securerandom'
    one_megabyte = 2 ** 20
    randString = SecureRandom.random_bytes(size_in_mb * one_megabyte)

    file = Tempfile.open("asset_test", Rails.root.join("tmp"))
    file.binmode
    file.write(randString)
    file.close
    file.open
  end

  def generate_table_contents(rows, cols)
    res = []
    if rows > 0
      res << (1..cols).map{ Faker::Team.state }.to_a
      for _ in 2..rows
        res << (1..cols).map{ rand * 1000 }.to_a
      end
    end
    return { data: res }.to_json
  end

  def generate_color
    res = "#"
    for _ in 1..6
      res << "0123456789ABCDEF"[rand(0..15)]
    end
    res
  end

  # Game of Thrones name generator v0.2 in all its glory!
  # Generate your favourite Westerosi characters with a single
  # line of code!
  def generate_got_name
    GAME_OF_THRONES_NAMES.sample
  end

  private

  GAME_OF_THRONES_NAMES = ["Tyrion Lannister", "Cersei Lannister", "Daenerys Targaryen", "Arya Stark", "Jon Snow", "Sansa Stark", "Jorah Mormont", "Jaime Lannister", "Sandor Clegan", "Tywin lannister", "Theon Greyjoy", "Samwell Tarly", "Joffrey Baratheon", "Catelyn Stark", "Bran Stark", "Petyr Baelish", "Varys", "Robb Stark", "Brienne of Tarth", "Bronn", "Shae", "Gendry", "Ygritte", "Margaery Tyrell", "Stannis Baratheon", "Missandei", "Davos Seaworth", "Melisandre", "Gilly", "Tormund Giantsbane", "Jeor Mormont", "Talisa Stark", "Eddard Stark", "Khal Drogo", "Ramsay Bolton", "Robert Baratheon", "Daario Naharis", "Viserys Targaryen", "Olenna Tyrell", "Maester Luwin", "Mance Rayder", "Oberyn Martell", "Ellaria Sand", "Gregor Clegane", "Walder Frey", "Robin Arryn", "Lysa Arryn", "Tommen Baratheon", "Myrcella Baratheon", "Renly Baratheon", "Salladhor Saan", "Roose Bolton", "Ramsay Bolton", "Balon Greyjoy", "Yara Greyjoy", "Kevan Lannister", "Lancel Lannister", "Polliver", "Amory Lorch", "Doran Martell", "Trystane Martell", "Areo Hotah", "Nymeria Sand", "Obara Sand", "Tyene Sand", "Rickon Stark", "Hodor", "Meera Reed", "Jojen Reed", "Osha", "Rodrik Cassel", "Jory Cassel", "Old Nan", "Jon Umber", "Barristan Selmy", "Grey Worm", "Edmure Tully", "Brynden Tully", "Loras Tyrell", "Mace Tyrell", "Maester Aemon", "Alliser Thorne", "Janos Slynt", "Grenn", "Pyp", "Yoren", "Qhorin Halfhand", "Benjen Stark", "Illyrio Mopatis", "Podrick Payne", "Jaqen H'ghar", "Beric Dondarrion", "Thoros of Myr", "Syrio Forel", "Grand Maester Pycelle", "Qyburn", "Meryn Trant", "The High Septon", "Dontos Hollard", "Ilyn Payne", "Craster", "Grey Wind", "Ghost", "Lady", "Nymeria", "Summer", "Shaggydog", "Balerion", "Meraxes", "Vhagar", "Drogon", "Rhaegal", "Viserion"]

end