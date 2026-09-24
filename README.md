# Bagnon 3.3.5

Bagnon (v2.13.3) backported to run on
World of Warcraft **3.3.5a (Wrath of the Lich King)**, with a reworked item sorter.

Bagnon replaces the default inventory, bank, keyring, guild bank and void storage windows with
single, unified frames.

## Installation

Copy the addon folders into `World of Warcraft/Interface/AddOns/`:

| Folder | Purpose |
| --- | --- |
| `Bagnon-3.3.5` | Core addon — inventory, bank and keyring frames (required) |
| `Bagnon_Config-3.3.5` | In-game options panels |
| `Bagnon_Forever-3.3.5` | Offline/cached item data for your other characters |
| `Bagnon_GuildBank-3.3.5` | Guild bank frame |
| `Bagnon_Tooltips-3.3.5` | Adds owned-item counts to tooltips |
| `Bagnon_VoidStorage-3.3.5` | Void storage frame |

Ace3, LibDataBroker-1.1 and LibItemSearch-1.0 are embedded in `Bagnon-3.3.5/libs`, so there is
nothing else to install.

The folders carry a `-3.3.5` suffix so they can't be confused with (or overwritten by) retail
Bagnon. Remove any old `Bagnon*` folders without the suffix before installing, or both copies
will load.

## What this fork changes

Everything below is on top of stock Bagnon 2.13.3.

### 3.3.5 compatibility

API calls introduced after 3.3.5 were reverted to their WotLK equivalents and every `.toc` was
retargeted to `## Interface: 30300`.

### Sorting rework

The client-side sorter (`Bagnon-3.3.5/utility/sorting.lua`) was largely rewritten:

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
