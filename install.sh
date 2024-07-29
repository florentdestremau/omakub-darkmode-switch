cat > $OMAKUB_PATH/bin/dark-mode-switch.sh <<EOT
#!/bin/bash

# Function to execute when dark mode is enabled
dark_mode_on() {
	echo "Dark mode enabled, setting \"Tokyo Night\" theme"
	export DESIRED_THEME="tokyo-night"
	set_theme
}

# Function to execute when light mode is enabled
light_mode_on() {
	echo "Light mode enabled, setting \"Red Pine\" theme"
	export DESIRED_THEME="rose-pine"
	set_theme
}

set_theme() {
	# Create a temporary gum function that returns the desired theme
	function gum() {
		if [[ \$1 == "choose" ]]; then
			echo "\$DESIRED_THEME"
		else
			command gum "\$@"
		fi
	}

	# Run the script with the overridden gum function
	( gum() { if [[ \$1 == "choose" ]]; then echo "\$DESIRED_THEME"; else command gum "\$@"; fi; }; source \$OMAKUB_PATH/bin/omakub-sub/theme.sh )
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

cat > /tmp/darkmode-monitor.service <<EOT
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
sudo systemctl start darkmode-monitor.service
