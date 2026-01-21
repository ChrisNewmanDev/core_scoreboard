# Me
Hello! If you’re enjoying the script and feel like supporting the work that went into it, consider buying me a coffee ☕
https://buymeacoffee.com/core_scripts

---

# core-scoreboard: Using the SetHeistInProgress Export

To set a heist as in progress (and start its cooldown timer) from another script, use the following export call:

```
exports['core-scoreboard']:SetHeistInProgress('heist_id', true)
```

- Replace `'heist_id'` with the id of the heist you want to start (e.g., `'pacific'`, `'fleeca'`, `'jewelry'`, `'union'`).
- The second argument should be `true` to start the heist (sets it in progress and starts cooldown), or `false` to mark it as not in progress (does not start cooldown).

## Example
```lua
-- Start Pacific Bank heist
exports['core-scoreboard']:SetHeistInProgress('pacific', true)

-- End Pacific Bank heist (does not start cooldown)
exports['core-scoreboard']:SetHeistInProgress('pacific', false)
```

## Notes
- When you set a heist to `true`, the scoreboard will show it as "In Progress" and start the cooldown timer.
- When you set a heist to `false`, it will no longer be "In Progress" but the cooldown will not be reset unless you set it to `true` again.
- Cooldown times are configured per heist in `config.lua`.

## Customizing Server Logo and Name

- **Server Name:**
  - Change the server name displayed on the scoreboard by editing `Config.ServerName` in `config.lua`.
  - Example:
    ```lua
    Config.ServerName = "My Awesome Server"
    ```

- **Server Logo:**
  - Replace the image at `html/img/server-logo.png` with your own logo file.
  - Make sure the filename and path match exactly (`server-logo.png` in the `img` folder).
  - The logo will automatically appear above the scoreboard when the UI is opened.

## Credits

- **Framework**: QB-Core
- **Developer**: ChrisNewmanDev

## Changelog

### Version 1.0.0 (January 21, 2026)
- Initial release
- Core scoreboard functionality
- Job count display
- Heist status tracking
- Cooldown timer system
- Custom server logo and name support
- SetHeistInProgress export
