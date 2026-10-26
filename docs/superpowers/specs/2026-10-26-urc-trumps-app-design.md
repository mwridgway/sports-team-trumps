# URC Trumps: mobile app, API and data job

Date: 26 Oct 2026
Screens: [URC Trumps iOS design canvas](https://claude.ai/artifact/GAAiFuy5Hs3v2mtZUP8wKs) (private)

## Intent

A Top Trumps game built on real United Rugby Championship (URC) players. You play the computer, or a friend on their own phone. Every card also opens into a **player file**, where you can read up on that player: how he's done in every match this season, where he went to school, the clubs he's played for, international caps, fitness and form, family, and odd facts. iOS ships first, as a native SwiftUI app. Android may follow as its own native app, so the data and server contracts stay platform-neutral.

## Goals

1. **The card fills the phone.** During a hand, the card takes the whole screen apart from a slim score bar (you, the ruck, your opponent) and the iOS safe areas. Each stat row is a tap target at least 44 pt tall.
2. **Two ways to play:** against the computer (works offline), or against a friend on another phone, joined by scanning a QR code or typing a short room code.
3. **Leader cards.** In each trump category, the player with the highest value across the whole URC player pool gets a silver foil card. It carries a "No.1 <category>" badge, and the leading stat row is picked out with a crown and "Most in URC". If players tie, they all get the silver card.
4. **A player file on every card**, reached with the "File" button on the card or "Both files" after a reveal:
   - **Season** (phase 1): every URC match this season, most recent first. Played matches show minutes, tackles, missed tackles, carries and metres; tapping a match shows every stat. Matches he missed show "Didn't play". The next fixture appears at the top.
   - **Career** (phase 1): URC totals for each season from 2021/22, from data we already hold.
   - **Story** (phase 2): school, clubs, international caps and squads, fitness and recent injuries, family, and "Did you know" facts. Every fact shows its source.
5. **An API on Vercel**, plus a scheduled job that pulls the latest URC data.

## Non-goals (for now)

- Pass-and-play on one phone, accounts and logins, leaderboards, chat, payments.
- Offline phone-to-phone play over Bluetooth (see Multiplayer for why).
- Competitions other than the URC.

## Anti-goals (failure even if it works)

- **Made-up facts.** Every Story fact needs a source link and a date it was checked. If we can't source something, we show nothing, never a guess.
- **Prying into private lives.** Family facts appear only if the player or a reputable outlet has made them public. Children are never named and their ages are never given; "father of two" is the most detail allowed. No home towns beyond place of birth, no partners' social media, nothing scraped from social media. Where nothing has been reported, the Family section says so (see the Story artboard).
- **Shrinking the card to fit chrome.** No tab bars or banners during play.
- **Leaking hidden cards.** In an online game, neither phone ever receives the other player's face-down cards.

## Constraints

- **Personal use only.** The app is for the owner and friends, through dev builds or TestFlight. There will be no public App Store release, so the copyrighted URC headshots (credited to agencies such as SNS Group) can be used. The public GitHub repo still must not contain the photos (`data/` is gitignored).
- **Data source.** The URC site runs on WPGraphQL at `https://www.unitedrugby.com/graphql`. It needs no key, but it isn't a published API, so it can change without notice and we should poll it gently. Confirmed fields:
  - `playerThemeSettings`: squads and player bios.
  - `playerseasonstats`: about 150 stats per player per season.
  - `matchstats(team_id: [Int], season_id: [Int])`: every fixture with its score and status, and, for finished matches, each player's stats under `stats_data.homeTeam/awayTeam.players[].stats` (`scoring.minutesPlayed`, `defence.totalTackles`, `defence.missedTackle`, `attack.carries`, `attack.metresMade`, and others). `season_id` is an Int, for example `202601`.
- **Not in the URC API:** schools, previous clubs, caps, injuries and family. These have to come from other sources (see Player stories).
- **Data quirk:** every player's `urc_debut` in `player_cards` reads `2026-09-11`, so it's wrong. Don't show it until it's fixed.
- **Secrets** go in Bitwarden Secrets Manager (project "Matthew Personal Project", keys prefixed `URC_TRUMPS_`) and in Vercel or GitHub. Set them in the same pass so they don't drift.
- **Apple:** team SHV4CBAT92, bundle ID `com.ridgbaks.urctrumps`, App Store Connect app 6826993962. CI uses the team's Admin App Store Connect API key (GitHub secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`).

## Decisions

Updated 26 Oct 2026: the owner chose a native SwiftUI app with Liquid Glass (replacing Expo), a simple Vercel Blob data store (replacing Postgres), and fully automated TestFlight builds.

| Area | Decision | Why |
| --- | --- | --- |
| App | **Native SwiftUI, iOS 26+ only**, Swift 6 strict concurrency, `@Observable`, no third-party packages. Project generated by XcodeGen from `ios/project.yml`. Built with the owner's SwiftUI skills (`swiftui-expert`, `swiftui-pro`). | The owner's call. iOS 26 only, so Liquid Glass needs no fallbacks. |
| Design system | **Liquid Glass**, following the owner's iOS design brief (`mwridgway/studza` `docs/native-ios/design-brief.md`). Glass is the control layer and ornament floating over full-bleed cards; content stays opaque. 375×812 pt (iPhone 13 mini) is the layout baseline. | Matches the owner's research and their stated preference to push glass onto content-adjacent ornament. |
| Data store | **Vercel Blob**: the data job publishes `urc.json` (players, stats, leaders, per-match rows) and the headshots as files. The app bundles a snapshot and will later check Blob for a newer one. | Simplest thing that works: no database to run. |
| API | **Small TypeScript functions on Vercel**, only where files aren't enough: online game rooms, and later "report a wrong fact". | Reading data needs no API; it's static files. |
| Online games | Game rooms in **Upstash Redis** (Vercel Marketplace), which supports atomic updates. The server deals and checks every move; phones poll or use server-sent events. | Blob can't do safe concurrent updates, and rooms are short-lived. |
| Data job | **GitHub Actions**: ingest from the URC GraphQL API, then export `urc.json` and photos. Today the TestFlight workflow runs it before each build. Next step: a scheduled job that publishes to Blob. | A full refresh takes minutes; Actions has no tight time limit. |
| Shipping | **`.github/workflows/testflight.yml`** on every push to `main` that touches `ios/` or `scripts/`, every Monday 06:00 SAST after the weekend round, and on demand. It runs tests, archives unsigned, and exports with cloud-managed Apple Distribution signing straight to TestFlight (`scripts/ios_release.sh`). | Fully automated, with no certificates stored in CI. |
| Joining | The host gets a room code (for example `RUCK 4827`) shown as a QR code holding `urctrumps://join/RUCK4827`. The guest scans it or types the code. | QR codes work across iPhone and Android. |
| Bluetooth "tap" | **Not in v1.** MultipeerConnectivity is iPhone-only and NFC phone-to-phone isn't open to apps. | Revisit as an iPhone-only extra if playing without signal matters. |
| vs Computer | Runs entirely on the phone. Easy picks a random stat. Medium picks the stat where its card ranks highest across the player pool. Hard picks the stat most likely to beat the cards it hasn't seen yet. | Plays offline. |

## The game

- **Categories (v1):** height (cm), weight (kg), tackles, tries, metres made, points. Height and weight come from the bio. The rest are URC career totals since 2021/22 from `player_cards`. The categories are defined in server config, not hard-coded, because choosing the final trump stats is still an open decision.
- **The deck:** 32 cards, 16 each. Every category leader is always in the deck, and the rest are random. Only players with at least 10 URC appearances qualify, except category leaders.
- **Rules:** these match the current artifact.
  - Whoever won the last hand picks the category. The higher number wins and takes both cards.
  - A draw puts both cards in the ruck, and the winner of the next hand takes the ruck too.
  - Take all 32 cards to win.
  - The host can set a time limit (10/20/30 min). When it runs out, whoever holds more cards wins.
- **Screens on the canvas:** Home, Your turn, Reveal (opponent's card on top, yours below, the result banner between), Leader card, Game over, Host (QR code), Join (scanner and code entry), Player file: Season, and Player file: Story. All are drawn at 375×812 in Liquid Glass.

## The look

The floodlit-pitch style of the existing artifact:

- **Colours:** dark green ground `#0d1a14`/`#13251c`, chalk text `#e9efe9`, cards `#f5f7f4`, and amber `#f2b134` as the only accent (your move, the winning result). Each club's colour runs as a band across the top of the card.
- **Fonts:** Big Shoulders Display for names and numbers and Barlow Condensed for card labels (both bundled, OFL). Controls use the system font with Dynamic Type.
- **Silver foil (leader cards only):** a metallic gradient border and background. On the phone it shimmers slowly as the device tilts (Core Motion), and the shimmer stops when the system's Reduce Motion setting is on.

## Data

### The game-data file (`urc.json`)

`scripts/export_app_data.py` reads `data/urc.db` and this season's `matchstats`, and writes `ios/URCTrumps/Resources/GameData/urc.json` plus 480 px JPEG headshots. Both are gitignored. The file holds:
- the categories and their leaders (ties all lead);
- every eligible player (at least 10 URC appearances with a photo, plus every category leader; 533 today) with bio, card stats, URC career by season, and a row for every match of their club this season (`played`, minutes, tackles made, missed tackles, carries, metres, tries, points and more).

Per-match `tackles` uses the API's `defence.tackle` (tackles made), which matches the card totals. `totalTackles` counts attempts.

### Vercel Blob (next step)

- `urc/latest.json` (the same shape as `urc.json`, plus a version), and `urc/headshots/<id>.jpg`.
- The scheduled data job uploads both after each ingest.
- On launch the app compares versions and downloads a newer file if there is one, so stats refresh without a new TestFlight build.

### Game rooms (phase 1b)

- `POST /api/rooms`: create a room and get a code.
- `POST /api/rooms/:code/join`: join a room.
- `GET /api/rooms/:id/view`: your own view of the game (your top card only).
- `POST /api/rooms/:id/moves`: make a move.

Room state lives in Upstash Redis with a 24-hour expiry. Phones identify themselves with an anonymous device token stored in the Keychain.

### Player stories (phase 2)

A separate, slower job, run weekly and on demand. For each player it:

1. Gathers candidate facts from Wikipedia and Wikidata, club and national-union profile pages, and reputable news outlets.
2. Uses Claude with web search to pull them out as structured facts, each with its source URL.
3. Saves them as drafts in Blob (`urc/facts/<player>.json`).

A small review page lets you publish or reject drafts. Only published facts reach the app. Fitness and recent injuries are refreshed more often, in-season, from club team announcements. The Story artboard shows real sourced facts for Nick Timoney as the model to follow.

## Getting ready for Android

- The data is plain JSON files in Blob and the room API is plain HTTP, so an Android app (Kotlin and Jetpack Compose) can use both unchanged.
- The game rules are small and fully covered by unit tests in `URCTrumpsTests`. An Android port reimplements them and runs the same test cases.
- Joining uses QR codes and app links, which Android supports.

## Phases

1. **Phase 1a (today):** the native app with play against the computer, leader cards, player files (Season, Career and Profile) and browsing, plus automated TestFlight builds.
2. **Phase 1b:** a scheduled data job publishing to Blob, refreshing the app's data on launch, and online games with a friend (QR code and room code).
3. **Phase 2:** the stories pipeline and review page, and the Story tab.
4. **Later:** Android.

## Left to the builder

- Card flip and foil animation details, with reduced-motion paths.
- How the computer's Medium and Hard levels are tuned.

## Open questions for later

- The final six trump categories. These are config, so this doesn't block the build.
- Whether the deck should be the whole player pool (893 players) or a curated "pack" per release.
