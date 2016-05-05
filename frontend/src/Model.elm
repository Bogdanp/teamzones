module Model (Message(..), Model) where

import Routes exposing (Sitemap)
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (..)

import Components.Invite as Invite


type Message
  = NoOp
  | Tick Timestamp
  | TimezoneChanged Timezone
  | PathChanged String
  | RouteTo Sitemap
  | ToInvite Invite.Message


type alias Model
  = { now : Timestamp
    , company : Company
    , user : User
    , team : Team
    , route : Sitemap
    , invite : Invite.Model
    }
