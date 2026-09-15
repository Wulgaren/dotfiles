tell application "Helium"
	if (count of windows) is 0 then
		activate
		make new window
		return
	end if

	-- Already on the non-Discord window: just foreground Helium.
	try
		if (URL of active tab of front window as text) does not contain "discord.com" then
			activate
			return
		end if
	end try

	repeat with w in windows
		try
			if (URL of active tab of w as text) does not contain "discord.com" then
				set index of w to 1
				activate
				return
			end if
		end try
	end repeat

	make new window
	activate
end tell
