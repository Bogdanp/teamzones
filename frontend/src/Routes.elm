module Routes (Sitemap(..), match, route) where

import Route exposing (..)


type Sitemap
  = DashboardR ()
  | InviteR ()
  | SettingsR ()

homeR = DashboardR := static ""
inviteR = InviteR := static "invite"
settingsR = SettingsR := static "settings"
sitemap = router [homeR, inviteR, settingsR]


match : String -> Sitemap
match = Route.match sitemap >> Maybe.withDefault (DashboardR ())


route : Sitemap -> String
route route =
  case route of
    DashboardR () -> reverse homeR []
    InviteR () -> reverse inviteR []
    SettingsR () -> reverse settingsR []
