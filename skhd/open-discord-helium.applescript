set target to "https://discord.com/app"

tell application "Helium"
	if (count of windows) is 0 then
		activate
		make new window with properties {URL:target}
		return
	end if

	-- Already on Discord: just foreground Helium.
	try
		if (URL of active tab of front window as text) contains "discord.com" then
			activate
			return
		end if
	end try

	repeat with w in windows
		try
			if (URL of active tab of w as text) contains "discord.com" then
				set index of w to 1
				activate
				return
			end if
		end try
	end repeat

	make new window with properties {URL:target}
	activate
end tell
