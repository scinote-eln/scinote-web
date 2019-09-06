require "yaml"

namespace :i18n do

  desc "Find unused keys for given locale (default: 'en'); currently only works on OSs that support 'grep' command"
  task :unused_keys, [ :lang ] => :environment do |_, args|

    def flatten_hash(my_hash, parent=[])
      my_hash.flat_map do |key, value|
        case value
          when Hash then flatten_hash(value, parent + [key])
          else [(parent + [key]).join("."), value]
        end
      end
    end

    lang = args[:lang] || "en"
    all_files = Dir.entries("config/locales").select { |f| f.ends_with?("#{lang}.yml") }
    all_keys = []

    all_files.each do |fname|
      yml = YAML.load_file("config/locales/#{fname}")
      res = Hash[*flatten_hash(yml)]
      res.keys.each do |key|
        all_keys << (key.start_with?("#{lang}.") ? key.sub("#{lang}.", "") : key)
      end
    end

    all_good = true
    all_keys.each do |key|
      `grep -rn #{key} .`
      next if $CHILD_STATUS.successful?

      if all_good
        all_good = false
        puts "Following keys are unused (for locale #{lang}):"
      end
      puts "  #{key}"
    end

    if all_good
      puts "No unused keys found!"
    end
  end

  desc "Find and list translation keys that do not exist in all locales"
  task :missing_keys => :environment do

    def collect_keys(scope, translations)
      full_keys = []
      translations.to_a.each do |key, translations|
        new_scope = scope.dup << key
        if translations.is_a?(Hash)
          full_keys += collect_keys(new_scope, translations)
        else
          full_keys << new_scope.join('.')
        end
      end
      return full_keys
    end

    # Make sure we've loaded the translations
    I18n.backend.send(:init_translations)
    puts "#{I18n.available_locales.size} #{I18n.available_locales.size == 1 ? 'locale' : 'locales'} available: #{I18n.available_locales.to_sentence}"

    # Get all keys from all locales
    all_keys = I18n.backend.send(:translations).collect do |check_locale, translations|
      collect_keys([], translations).sort
    end.flatten.uniq
    puts "#{all_keys.size} #{all_keys.size == 1 ? 'unique key' : 'unique keys'} found."

    missing_keys = {}
    all_keys.each do |key|

      I18n.available_locales.each do |locale|
        I18n.locale = locale
        begin
          result = I18n.translate(key, :raise => true)
        rescue I18n::MissingInterpolationArgument
          # noop
        rescue I18n::MissingTranslationData
          if missing_keys[key]
            missing_keys[key] << locale
          else
            missing_keys[key] = [locale]
          end
        end
      end
    end

    puts "#{missing_keys.size} #{missing_keys.size == 1 ? 'key is missing' : 'keys are missing'} from one or more locales:"
    missing_keys.keys.sort.each do |key|
      puts "'#{key}': Missing from #{missing_keys[key].join(', ')}"
    end

  end
end
