require 'openssl'
require 'base64'

def sha0_base64(data)
  digest = OpenSSL::Digest.new('sha')
  digest.update(data)
  Base64.strict_encode64(digest.digest)
end

def nt_hash_base64(password)
  utf16_password = password.chars.map{ |c| c + "\0" }.join('')
  digest = OpenSSL::Digest.new('md4')
  digest.update(utf16_password)
  Base64.strict_encode64(digest.digest)
end

def sha256(data)
  digest = OpenSSL::Digest.new('sha256')
  digest.update(data)
  digest
end
