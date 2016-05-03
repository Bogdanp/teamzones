module Routes where

import Route exposing (..)


type Sitemap
  = HomeR ()
  | InviteR ()
  | SettingsR ()

homeR = HomeR := static ""
inviteR = InviteR := static "invite"
settingsR = SettingsR := static "settings"
sitemap = router [homeR, inviteR, settingsR]


match : String -> Sitemap
match = Route.match sitemap >> Maybe.withDefault (HomeR ())


route : Sitemap -> String
route r =
  case r of
    HomeR () -> reverse homeR []
    InviteR () -> reverse inviteR []
    SettingsR () -> reverse settingsR []
