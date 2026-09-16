set target to "https://discord.com/app"

tell application "Helium"
	if (count of windows) is 0 then
		activate
		set w to make new window
		set URL of active tab of w to target
		return
	end if

	-- Already on a Discord tab: just foreground Helium.
	try
		if (URL of active tab of front window as text) contains "discord.com" then
			activate
			return
		end if
	end try

	repeat with wi from 1 to (count of windows)
		set w to window wi
		repeat with ti from 1 to (count of tabs of w)
			try
				if (URL of tab ti of w as text) contains "discord.com" then
					set active tab index of w to ti
					set index of w to 1
					activate
					return
				end if
			end try
		end repeat
	end repeat

	set w to make new window
	set URL of active tab of w to target
	activate
end tell
