sudo apt update
sudo apt install ruby git libsodium18
git clone git@github.com:tyage/my-kitchen.git
cd my-kitchen
gem install bundle
bundle i --path=vendor/bundle
