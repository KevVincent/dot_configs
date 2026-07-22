# Brave bookmarks

`Bookmarks` is a snapshot of the Brave `Default` profile's bookmarks file.
It preserves bookmark folders and ordering, but it does not contain passwords,
cookies, history, or every browser preference.

## Restore on Linux

1. Install and launch Brave once so that it creates a profile, then close Brave
   completely before replacing the bookmarks file.
2. Choose the applicable profile directory:

   - Snap: `~/snap/brave/current/.config/BraveSoftware/Brave-Browser/Default`
   - Standard package: `~/.config/BraveSoftware/Brave-Browser/Default`

   If Brave uses a named profile, replace `Default` with that profile directory,
   such as `Profile 1`.
3. Back up the new profile's existing `Bookmarks` file, if present.
4. Copy this repository's `brave/Bookmarks` file into the profile directory.
5. Start Brave and verify the bookmarks.

For ongoing synchronization across devices, use Brave Sync in addition to this
point-in-time backup.
