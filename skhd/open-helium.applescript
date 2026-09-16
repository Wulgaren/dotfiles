tell application "Helium"
	if (count of windows) is 0 then
		activate
		make new window
		return
	end if

	-- Already on a non-Discord tab: just foreground Helium.
	try
		if (URL of active tab of front window as text) does not contain "discord.com" then
			activate
			return
		end if
	end try

	-- Prefer a window whose active tab is already non-Discord; never switch tabs.
	repeat with wi from 1 to (count of windows)
		set w to window wi
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
