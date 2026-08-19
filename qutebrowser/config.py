import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import catppuccin

config.load_autoconfig()

catppuccin.setup(c, "frappe", True)

_font = "12pt JetBrainsMono Nerd Font"
c.fonts.default_family = ["JetBrainsMono Nerd Font"]
c.fonts.default_size = "12pt"
c.fonts.statusbar = _font
c.fonts.tabs.selected = _font
c.fonts.tabs.unselected = _font
c.fonts.downloads = _font
c.fonts.hints = f"bold {_font}"
c.fonts.contextmenu = _font
c.fonts.completion.entry = _font
c.fonts.completion.category = f"bold {_font}"
c.fonts.keyhint = _font
c.fonts.messages.error = _font
c.fonts.prompts = _font
c.fonts.debug_console = _font

# Allow JavaScript clipboard read/write on all websites
config.set("content.javascript.clipboard", "access")

c.url.searchengines = {"DEFAULT": "https://nat-search.vercel.app/?q={}"}
c.url.start_pages = "https://nat-search.vercel.app/"
c.url.default_page = "https://nat-search.vercel.app/"
