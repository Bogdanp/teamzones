module Model exposing (Msg(..), Model, Flags)

import Components.CurrentProfile as CP
import Components.Invite as Invite
import Routes exposing (Sitemap)
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (..)


type Msg
    = NoOp
    | Tick Timestamp
    | TimezoneChanged Timezone
    | PathChanged String
    | RouteTo Sitemap
    | ToInvite Invite.Msg
    | ToCurrentProfile CP.Msg


type alias Model =
    { now : Timestamp
    , company : Company
    , user : User
    , team : Team
    , route : Sitemap
    , invite : Invite.Model
    , currentProfile : CP.Model
    }


type alias Flags =
    { path : String
    , now : Timestamp
    , company : Company
    , user : ContextUser
    , team : List ContextUser
    }
