project = "Mod SDK"
title = "DST Mod SDK | LDoc"
description = "dst-mod-sdk"
full_description = "Mod SDK for the game [Don\'t Starve Together](https://www.klei.com/games/dont-starve-together)." .. "\n\n" ..
    [[- **Source Code:** [https://github.com/dstmodders/dst-mod-sdk](https://github.com/dstmodders/dst-mod-sdk)]]

file = {
    "./",
    exclude = {
        "./spec/",
    },
}

dir = "docs"
format = "markdown"
readme = "readme"
sort_modules = true
style = "./docs/ldoc/"
use_markdown_titles = true
