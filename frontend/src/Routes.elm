module Routes (Sitemap(..), match, route) where

import Route exposing (..)


type Sitemap
  = DashboardR ()
  | InviteR ()
  | SettingsR ()
  | CurrentProfileR ()

homeR = DashboardR := static ""
inviteR = InviteR := static "invite"
settingsR = SettingsR := static "settings"
currentProfileR = CurrentProfileR := static "profile"
sitemap = router [homeR, inviteR, settingsR, currentProfileR]


match : String -> Sitemap
match = Route.match sitemap >> Maybe.withDefault (DashboardR ())


route : Sitemap -> String
route route =
  case route of
    DashboardR () -> reverse homeR []
    InviteR () -> reverse inviteR []
    SettingsR () -> reverse settingsR []
    CurrentProfileR () -> reverse currentProfileR []
