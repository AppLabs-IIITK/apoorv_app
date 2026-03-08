# Apoorv App User Manual (Admins and Subadmins)

This guide is for Admins and Subadmins.

Everyone uses the same 4-tab UI:
`Home` (Feed), `Maps`, `Points`, `Profile`.
Admin/Subadmin accounts simply get additional management buttons.

## Roles and Access

### Admins and Subadmins
- Admin/Subadmin access is granted based on your email being listed in the app configuration.
- If your email is listed, you will see extra management controls across Feed, Maps, and Profile.

### Shopkeepers
Shopkeepers are managed by Admin/Subadmin:
- Shopkeeper status is controlled using a shopkeeper flag on the user.
- Shopkeeper capability also depends on shop points (`Shop Coins`) being assigned.

## Core Concepts To Know

### Points and Transactions
- Normal users transfer `Points` between each other.
- All transfers create transaction entries, which can be reviewed via:
  - `All Transactions` (My/Global)
  - `Inspect` screens (per-user transaction view)

### Welcome Bonus (College Users)
- New college-email users receive a welcome bonus of `50` points on first sign-in.

### Inter-College Transfer Rules
- College users cannot send points to outside-college users.
- Outside-college users can send points to college users (if they have enough points).

### Shop Rewards (Shop Coins) Rules
When a shopkeeper pays in Shopkeeper Mode:
- Reward amount is limited to `150` points per user.
- A shopkeeper can reward the same user only once.
- The shopkeeper must have enough shop points.
- Admins may have override capability for shop reward limits.

## Tab 1: Home (Feed) Admin Controls

Regular users can only view the Feed. Admin/Subadmin accounts can edit it.

### Enter and Exit Edit Mode
- On the Feed header, tap the `edit` icon to enter edit mode.
- Tap the `check` icon to exit edit mode.

### Add a Feed Item
1. Enter edit mode.
2. Scroll to the bottom and tap `Add feed item`.
3. Fill in:
   - `Title`
   - `Text (optional)`
   - `Add Image` (optional)
   - `Priority` toggle (high-importance announcement)
4. Tap `Save`.

### Edit or Delete a Feed Item
- In edit mode, each feed card shows:
  - `Edit`
  - `Delete`
- Deleting asks for confirmation and removes it for everyone.

## Tab 2: Maps Admin Controls

Regular users can only view the map and events. Admin/Subadmin accounts can manage locations and events.

### Add a Location
- Tap `Add Location` (pin icon) in the map top bar.
- Pan the map to place the pin, then confirm.
- Fill in location name and marker colors, then save.

### Move a Location
- For editable markers, use the move interaction (when available) to reposition.
- Confirm the new position to save.

### Add an Event to a Location
You can add events in two ways:
- Tap a location marker to open its bottom sheet, then use `Add Event` (appears only for Admin/Subadmin).
- Or manage events from event screens where edit controls are visible.

Event fields typically include:
- Title (required)
- Time (required)
- Day (Day 1 / Day 2 / Day 3)
- Location and optional room number
- Optional description
- Optional image
- Optional colors (event card colors)

### Edit or Delete an Event
- Open an event, then use the `Edit` and `Delete` buttons (Admin/Subadmin only).
- In `All Events`, Admin/Subadmin may also see a menu to edit/delete.

### View All Events (For Everyone)
- Tap the `View All Events` button in the map top bar.
- Switch between Day 1/2/3 tabs and open event details.

## Tab 3: Points (Admin/Subadmin Usage)

Admin/Subadmin accounts use the Points tab like normal users:
- Search users to pay
- Scan/show QR
- Open the leaderboard
- Open All Transactions (My/Global)

Recommended admin workflow when resolving issues:
1. Open `All Transactions` and switch to `Global Transactions`.
2. Tap a transaction to open `Transaction Details`.
3. From details, tap a participant to open payment if you need to correct/redo a transfer.

## Tab 4: Profile Admin Controls

### Manage Shop Keepers
- In Profile, Admin/Subadmin accounts get a management shortcut to `Manage Shop Keepers`.

Inside `Manage Shop Keepers` you can:
- Add a shopkeeper:
  - Enter `Email or Roll No`
  - Set `Initial shop points`
- Edit shop points for an existing shopkeeper.
- Remove a shopkeeper:
  - Disables shopkeeper mode
  - Sets shop points to `0`

### Inspect (Self)
- Tap your profile picture to open `Inspect <Your Name>`.

### Inspect (Other Users)
You can open a user’s Inspect screen from the payment page:
1. Start a payment to a user (search/QR/leaderboard/transaction details).
2. Tap the top-right `Inspect` button.

Inspect is useful for:
- Transparency and audit: review a user’s sent/received history with totals and filters.
- Fraud checks: spot suspicious patterns (rapid repeats, unusual spikes, shop reward misuse).
- Dispute resolution: verify what happened, when, and between which accounts.
- Separating normal transfers vs shop transactions for clearer investigations.
