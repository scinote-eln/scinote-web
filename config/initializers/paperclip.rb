
if ENV['PAPERCLIP_HASH_SECRET'].nil?
  puts "WARNING! Environment variable PAPERCLIP_HASH_SECRET must be set."
  exit 1
end

Paperclip::Attachment.default_options.merge!(
  hash_data: ':class/:attachment/:id/:style',
  hash_secret: ENV['PAPERCLIP_HASH_SECRET'],
  preserve_files: true,
  url: '/system/:class/:attachment/:id_partition/:hash/:style/:filename'
)

Paperclip::UriAdapter.register

if ENV['PAPERCLIP_STORAGE'] == "s3"

  if ENV['S3_BUCKET'].nil? or ENV['AWS_REGION'].nil? or
    ENV['AWS_ACCESS_KEY_ID'].nil? or ENV['AWS_SECRET_ACCESS_KEY'].nil?
    puts "WARNING! Environment variables S3_BUCKET, AWS_REGION, " +
         "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set."
    exit 1
  end
  Paperclip::Attachment.default_options.merge!({
    url: ':s3_domain_url',
    path: '/:class/:attachment/:id_partition/:hash/:style/:filename',
    storage: :s3,
    s3_region: ENV['AWS_REGION'],
    s3_host_name: "s3.#{ENV['AWS_REGION']}.amazonaws.com",
    s3_protocol: 'https',
    s3_credentials: {
      bucket: ENV['S3_BUCKET'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    },
    s3_permissions: {
      original: :private,
      medium: :private
    },
    s3_storage_class: {
      medium: :REDUCED_REDUNDANCY,
      thumb: :REDUCED_REDUNDANCY,
      icon: :REDUCED_REDUNDANCY,
      icon_small: :REDUCED_REDUNDANCY
    }
  })
elsif ENV['PAPERCLIP_STORAGE'] == "filesystem"
  Paperclip::Attachment.default_options.merge!({
    storage: :filesystem
  })

end

Paperclip::Attachment.class_eval do
  def is_stored_on_s3?
    options[:storage].to_sym == :s3
  end

  def fetch
    Paperclip.io_adapters.for self
  end
end

module Paperclip
  # Checks file for spoofing
  class MediaTypeSpoofDetector
    def spoofed?
      if has_name? && has_extension? && (media_type_mismatch? ||
        mapping_override_mismatch?)
        Paperclip.log("Content Type Spoof: Filename #{File.basename(@name)} "\
          "(#{supplied_content_type} from Headers, #{content_types_from_name} "\
          "from Extension), content type discovered: "\
          "#{calculated_content_type}. See documentation to allow this "\
          "combination.")
        true
      else
        false
      end
    end

    private

    # Determine file content type from its name
    def content_types_from_name
      @content_types_from_name ||=
        Paperclip.run('mimetype', '-b -- :file_name', file_name: @name).chomp
    end

    # Determine file media type from its name
    def media_types_from_name
      @media_types_from_name ||= extract_media_type content_types_from_name
    end

    # Determine file content type from mimetype command
    def type_from_mimetype_command
      @type_from_mimetype_command ||=
        Paperclip.run('mimetype', '-b -- :file', file: @file.path).chomp
    end

    # Determine file media type from mimetype command
    def media_type_from_mimetype_command
      @media_type_from_mimetype_command ||=
        extract_media_type type_from_mimetype_command
    end

    # Determine file content type from it's content (file and mimetype command)
    def type_from_file_command
      unless defined? @type_from_file_command
        @type_from_file_command =
          Paperclip.run('file', '-b --mime -- :file', file: @file.path)
                   .split(/[:;]\s+/).first

        if allowed_spoof_exception?(@type_from_file_command,
                                    media_type_from_file_command) ||
           (@type_from_file_command.in?(%w(text/plain text/html)) &&
            media_type_from_mimetype_command.in?(%w(text application)))
          # File content type is generalized, so rely on file extension for
          # correct/more specific content type
          @type_from_file_command = type_from_mimetype_command
        end
      end
      @type_from_file_command
    rescue Cocaine::CommandLineError
      ''
    end

    # Determine file media type from it's content (file and mimetype command)
    def media_type_from_file_command
      @media_type_from_file_command ||=
        extract_media_type type_from_file_command
    end

    def extract_media_type(content_type)
      if content_type.empty?
        ''
      else
        content_type.split('/').first
      end
    end

    def media_type_mismatch?
      calculated_type_mismatch?
    end

    # Checks file media type mismatch between file's name and header
    # NOTE: Can't rely on headers, as different OS can have different file type
    # MIME mappings
    def supplied_type_mismatch?
      !allowed_spoof_exception?(supplied_content_type, supplied_media_type) &&
        media_types_from_name != supplied_media_type
    end

    # Checks file media type mismatch between file's name and content
    def calculated_type_mismatch?
      !allowed_spoof_exception?(calculated_content_type,
                                calculated_media_type) &&
        media_types_from_name != calculated_media_type
    end

    # Checks file content type mismatch between file's name and content
    def mapping_override_mismatch?
      !allowed_spoof_exception?(calculated_content_type,
                                calculated_media_type) &&
        content_types_from_name != calculated_content_type
    end

    # Check if we have a file spoof exception which is allowed/safe
    def allowed_spoof_exception?(content_type, media_type)
      content_type == 'application/octet-stream' ||
        (content_type == 'inode/x-empty' && @file.size.zero?) ||
        (content_type == 'text/x-c' &&
         content_types_from_name == 'text/x-java') ||
        (media_type.in?(%w(image audio video)) &&
         media_type == media_types_from_name) ||
        (content_types_from_name.in? %W(#{}
                                        text/plain
                                        application/octet-stream)) ||
        # Types taken from: http://filext.com/faq/office_mime_types.php and
        # https://www.openoffice.org/framework/documentation/mimetypes/mimetypes.html
        #
        # Generic application
        (Set[content_type, content_types_from_name].subset? Set.new %w(
          text/rtf
          application/rtf
        )) ||
        # Word processor application
        (Set[content_type, content_types_from_name].subset? Set.new %w(
          application/zip
          application/vnd.ms-office
          application/msword
          application/msword-template
          application/vnd.openxmlformats-officedocument.wordprocessingml.document
          application/vnd.openxmlformats-officedocument.wordprocessingml.template
          application/vnd.ms-word.document.macroEnabled.12
          application/vnd.ms-word.template.macroEnabled.12
          application/vnd.oasis.opendocument.text
          application/vnd.oasis.opendocument.text-template
          application/vnd.oasis.opendocument.text-web
          application/vnd.oasis.opendocument.text-master
          application/vnd.sun.xml.writer
          application/vnd.sun.xml.writer.template
          application/vnd.sun.xml.writer.global
          application/vnd.stardivision.writer
          application/vnd.stardivision.writer-global
          application/x-starwriter
        )) ||
        # Spreadsheet application
        (Set[content_type, content_types_from_name].subset? Set.new %w(
          application/zip
          application/vnd.ms-office
          application/vnd.ms-excel
          application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
          application/vnd.openxmlformats-officedocument.spreadsheetml.template
          application/vnd.ms-excel.sheet.macroEnabled.12
          application/vnd.ms-excel.template.macroEnabled.12
          application/vnd.ms-excel.addin.macroEnabled.12
          application/vnd.ms-excel.sheet.binary.macroEnabled.12
          application/vnd.oasis.opendocument.spreadsheet
          application/vnd.oasis.opendocument.spreadsheet-template
          application/vnd.sun.xml.calc
          application/vnd.sun.xml.calc.template
          application/vnd.stardivision.calc
          application/x-starcalc
          application/CDFV2-encrypted
        )) ||
        # Presentation application
        (Set[content_type, content_types_from_name].subset? Set.new %w(
          application/zip
          application/vnd.ms-office
          application/vnd.ms-powerpoint
          application/vnd.openxmlformats-officedocument.presentationml.presentation
          application/vnd.openxmlformats-officedocument.presentationml.template
          application/vnd.openxmlformats-officedocument.presentationml.slideshow
          application/vnd.ms-powerpoint.addin.macroEnabled.12
          application/vnd.ms-powerpoint.presentation.macroEnabled.12
          application/vnd.ms-powerpoint.template.macroEnabled.12
          application/vnd.ms-powerpoint.slideshow.macroEnabled.12
          application/vnd.oasis.opendocument.presentation
          application/vnd.oasis.opendocument.presentation-template
          application/vnd.sun.xml.impress
          application/vnd.sun.xml.impress.template
          application/vnd.stardivision.impress
          application/vnd.stardivision.impress-packed
          application/x-starimpress
          text/x-gettext-translation-template
        )) ||
        # Graphics application
        (Set[content_type, content_types_from_name].subset? Set.new %w(
          application/vnd.ms-office
          application/vnd.oasis.opendocument.graphics
          application/vnd.oasis.opendocument.graphics-template
          application/vnd.sun.xml.draw
          application/vnd.sun.xml.draw.template
          application/vnd.stardivision.draw
          application/x-stardraw
        )) ||
        # Formula application
        (Set[content_type, content_types_from_name].subset? Set.new %w(
          application/vnd.ms-office
          application/vnd.oasis.opendocument.formula
          application/vnd.sun.xml.math
          application/vnd.stardivision.math
          application/x-starmath
        )) ||
        # Chart application
        (Set[content_type, content_types_from_name].subset? Set.new %w(
          application/vnd.ms-office
          application/vnd.oasis.opendocument.chart
          application/vnd.stardivision.chart
          application/x-starchart
        ))
    end
  end
end
