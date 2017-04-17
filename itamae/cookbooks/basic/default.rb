packages = %w(vim zsh git tig less curl wget ruby)
packages.each do |package|
  package package do
    action :install
  end
end
