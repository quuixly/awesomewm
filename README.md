# awesomewm
Dotfiles for awesomewm + arch.

# Packages
sudo pacman -S brightnessctl alacritty firefox nemo git ksnip pipewire-pulse upower pamixer rofi btop os-prober zsh lightdm awesome

# Installation
```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo nano /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```


# Key shortcuts
`win + t` Open alacritty

`win + f` Open firefox

`win + e` Open nemo

`win + r` Open rofi

`win + q` Close current window

`shift + 1-9` Move current window to another workspace

`win + 1-9` Go to another workspace

`win + shift + s` Make a screenshoot

