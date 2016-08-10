module WopiUtil
  require 'open-uri'


  DISCOVERY_TTL = 60*60*24
  DISCOVERY_TTL.freeze

  def get_action(extension, activity)
    discovery = WopiDiscovery.first
    if discovery.nil? || discovery.expires < Time.now.to_i
      initializeDiscovery(discovery)
    end

    action = WopiAction.find_action(extension,activity)

  end

  private
  # Currently only saves Excel, Word and PowerPoint view and edit actions
  def initializeDiscovery(discovery)
    begin
      Rails.logger.warn "Initializing discovery"
      unless discovery.nil?
        discovery.destroy
      end

      @doc = Nokogiri::XML(open(ENV["WOPI_DISCOVERY_URL"]))

      discovery = WopiDiscovery.new
      discovery.expires = Time.now.to_i + DISCOVERY_TTL
      key = @doc.xpath("//proof-key")
      discovery.proof_key_mod = key.xpath("@modulus").first.value
      discovery.proof_key_exp = key.xpath("@exponent").first.value
      discovery.proof_key_old_mod = key.xpath("@oldmodulus").first.value
      discovery.proof_key_old_exp = key.xpath("@oldexponent").first.value
      discovery.save!

      @doc.xpath("//app").each do |app|
        app_name = app.xpath("@name").first.value
        if ["Excel","Word","PowerPoint","WopiTest"].include?(app_name)
          wopi_app = WopiApp.new
          wopi_app.name = app.xpath("@name").first.value
          wopi_app.icon = app.xpath("@favIconUrl").first.value
          wopi_app.wopi_discovery_id=discovery.id
          wopi_app.save!
          app.xpath("action").each do |action|
            name = action.xpath("@name").first.value
            if ["view","edit","wopitest"].include?(name)
              wopi_action = WopiAction.new
              wopi_action.action = name
              wopi_action.extension = action.xpath("@ext").first.value
              wopi_action.urlsrc = action.xpath("@urlsrc").first.value
              wopi_action.wopi_app_id = wopi_app.id
              wopi_action.save!
            end
          end
        end
      end
    rescue
      Rails.logger.warn "Initialization failed"
      discovery = WopiDiscovery.first
      unless discovery.nil?
        discovery.destroy
      end
    end

  end


end