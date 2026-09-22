# Bagnon 3.3.5

A fork of Tuller's Bagnon (v2.13.3) backported to run on
World of Warcraft **3.3.5a (Wrath of the Lich King)**, with a reworked item sorter.

Bagnon replaces the default inventory, bank, keyring, guild bank and void storage windows with
single, unified frames.

## Installation

Copy the addon folders into `World of Warcraft/Interface/AddOns/`:

| Folder | Purpose |
| --- | --- |
| `Bagnon` | Core addon — inventory, bank and keyring frames (required) |
| `Bagnon_Config` | In-game options panels |
| `Bagnon_Forever` | Offline/cached item data for your other characters |
| `Bagnon_GuildBank` | Guild bank frame |
| `Bagnon_Tooltips` | Adds owned-item counts to tooltips |
| `Bagnon_VoidStorage` | Void storage frame |

Ace3, LibDataBroker-1.1 and LibItemSearch-1.0 are embedded in `Bagnon/libs`, so there is nothing
else to install.

## What this fork changes

Everything below is on top of stock Bagnon 2.13.3.

### 3.3.5 compatibility

API calls introduced after 3.3.5 were reverted to their WotLK equivalents and every `.toc` was
retargeted to `## Interface: 30300`.

### Sorting rework

The client-side sorter (`Bagnon/utility/sorting.lua`) was largely rewritten:

* **Sort direction is now an option.** "Reverse sort order" in the frame options controls which
  end of your bags a sort fills from. Previously the reversed ordering was hardcoded.
* **Bag display order is no longer tied to it.** Bag buttons always draw front to back; the
  option only affects where the sorter puts things.
* **Per-bag sort exclusion.** Right-click a bag button to exclude it from sorting. Excluded bags
  are dimmed, stay fully visible and usable, and the sorter neither reads from nor writes to
  them — useful for keeping a quiver, a profession bag or a "do not touch" bag intact. The flag
  is saved per character, per frame (inventory, bank and keyring track their own).
* **The guild bank can be sorted.** Sorting previously only understood the inventory's bag
  layout. The sorter now talks to item frames through a small interface
  (`CanSortItems`, `GetSortableBags`, `GetSortBagSize`, `GetSortBagFamily`, `GetSortSlotInfo`,
  `PickupSortItem`, `GetSortDelay`), and the guild bank supplies its own implementation that
  treats the currently viewed tab as a single container. It refuses to run on tabs you lack
  deposit rights to, and paces its passes wider apart because every move is a server round trip.

### Sorting bug fixes

* A sort started while another was still running no longer leaves the old one firing timers
  against a stale frame.
* Uncached items (`GetItemInfo` returning nothing) no longer abort a sort — stack size, count,
  quality, icon, level and name all fall back to safe values instead of comparing `nil`.
* Items whose container reports no quality fall back to the item's own rarity.
* A move that could not be performed no longer counts as progress, so the sorter can settle
  instead of rescheduling itself forever. A 100-pass ceiling backs that up as a hard stop.
* Sorting is blocked on cached (offline character) frames, where the moves would do nothing.

## Credits

Bagnon is by **Tuller**. 3.3.5 compatibility reverts by **Richard Steininger**.
