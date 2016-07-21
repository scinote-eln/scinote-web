module Encryptor
  def decrypt(data)
    return '' unless data.present?
    cipher = build_cipher(:decrypt, 'f5awRubeTUd2E*8duxum')
    cipher.update(Base64.urlsafe_decode64(data).unpack('m')[0]) + cipher.final
  end

  def encrypt(data)
    return '' unless data.present?
    cipher = build_cipher(:encrypt, 'f5awRubeTUd2E*8duxum')
    Base64.urlsafe_encode64([cipher.update(data) + cipher.final].pack('m'))
  end

  def build_cipher(type, password)
    cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC').send(type)
    cipher.pkcs5_keyivgen(password)
    cipher
  end
end