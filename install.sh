DARK_THEME=$(gum choose "Tokyo Night" "Catppuccin" "Nord" "Everforest" "Gruvbox" "Kanagawa" --selected "Tokyo Night" --header "Choose your dark theme" --height 10 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
LIGHT_THEME=$(gum choose "Rose Pine" --selected "Rose Pine" --header "Choose your light theme" --height 10 | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

\cat > $OMAKUB_PATH/bin/dark-mode-switch.sh <<EOT
#!/bin/bash

dark_mode_on() {
	export THEME="$DARK_THEME"
	echo "Dark mode enabled, setting $DARK_THEME theme"
	set_theme
}

light_mode_on() {
	export THEME="$LIGHT_THEME"
	echo "Light mode enabled, setting $LIGHT_THEME theme"
	set_theme
}

set_theme() {
	cp $OMAKUB_PATH/themes/\$THEME/alacritty.toml ~/.config/alacritty/theme.toml
	cp $OMAKUB_PATH/themes/\$THEME/zellij.kdl ~/.config/zellij/themes/\$THEME.kdl
	sed -i "s/theme \".*\"/theme \"\$THEME\"/g" ~/.config/zellij/config.kdl
	cp $OMAKUB_PATH/themes/\$THEME/neovim.lua ~/.config/nvim/lua/plugins/theme.lua
	source $OMAKUB_PATH/themes/\$THEME/gnome.sh
	source $OMAKUB_PATH/themes/\$THEME/vscode.sh
}


check_mode() {
    local mode=\$(gsettings get org.gnome.desktop.interface color-scheme)
    if [[ \$mode == *"prefer-dark"* ]]; then
        dark_mode_on
    else
        light_mode_on
    fi
}

# Monitor changes in the settings
while true; do
    current_mode=\$(gsettings get org.gnome.desktop.interface color-scheme)
    if [ "\$current_mode" != "\$previous_mode" ]; then
        previous_mode=\$current_mode
        check_mode
    fi
    sleep 1
done
EOT

sudo chmod +x $OMAKUB_PATH/bin/dark-mode-switch.sh

\cat > /tmp/darkmode-monitor.service <<EOT
[Unit]
Description=Dark Mode Monitor
After=graphical-session.target

[Service]
Type=simple
ExecStart=$OMAKUB_PATH/bin/dark-mode-switch.sh
Restart=always
User=$USER
Environment=OMAKUB_PATH=$OMAKUB_PATH
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

[Install]
WantedBy=default.target
EOT

sudo mv /tmp/darkmode-monitor.service /etc/systemd/system/darkmode-monitor.service

sudo systemctl daemon-reload
sudo systemctl enable darkmode-monitor.service
sudo systemctl restart darkmode-monitor.service

echo "All done ! Try switching light/dark mode to check it out 😉"
