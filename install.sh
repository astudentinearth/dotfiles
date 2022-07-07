#!/bin/bash
echo ===Configuring i3===
mkdir -p ~/.config/i3
cp ./config ~/.config/i3/config

echo ===Configuring polybar===
mkdir -p ~/.config/polybar
cp ./config-polybar ~/.config/polybar/config.ini
cp ./launch.sh ~/.config/polybar/launch.sh
chmod +x ~/.config/polybar/launch.sh

echo ===Configuring rofi===
mkdir -p ~/.config/rofi
cp ./config.rasi ~/.config/rofi/config.rasi

echo ===Configuring alacritty===
cp ./alacritty.yml ~/.config/alacritty/alacritty.yml

echo ===Configuring picom==
mkdir -p ~/.config/picom/
cp ./picom.conf ~/.config/picom/picom.conf

echo Done. Restart i3.
