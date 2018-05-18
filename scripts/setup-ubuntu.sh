sudo apt update
sudo apt install ruby ruby-dev gcc make git
git clone https://github.com/tyage/my-kitchen.git
cd my-kitchen
sudo gem install bundle
bundle i --path=vendor/bundle
