module Model exposing (Msg(..), Model, Flags)

import Components.CurrentProfile as CP
import Components.Invite as Invite
import Components.Settings as Settings
import Routes exposing (Sitemap)
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (..)


type Msg
    = Tick Timestamp
    | TimezoneChanged Timezone
    | PathChanged String
    | RouteTo Sitemap
    | ToInvite Invite.Msg
    | ToSettings Settings.Msg
    | ToCurrentProfile CP.Msg


type alias Model =
    { now : Timestamp
    , company : Company
    , user : User
    , team : Team
    , teamMembers : List User
    , timezones : List Timezone
    , route : Sitemap
    , invite : Invite.Model
    , settings : Settings.Model
    , currentProfile : CP.Model
    }


type alias Flags =
    { path : String
    , now : Timestamp
    , company : Company
    , user : ContextUser
    , team : List ContextUser
    , timezones : List Timezone
    }
