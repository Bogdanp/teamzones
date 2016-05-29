module Model exposing (ContextMsg(..), Msg(..), Model, Flags)

import Components.CurrentProfile as CP
import Components.Integrations as Integrations
import Components.Invite as Invite
import Components.Notifications as Notifications
import Components.Profile as Profile
import Components.Settings as Settings
import Routes exposing (Sitemap)
import Time exposing (Time)
import Timestamp exposing (Timestamp, Timezone)
import Types exposing (..)


type ContextMsg
    = DeleteUser String


type Msg
    = Tick Timestamp
    | TimezoneChanged Timezone
    | RouteTo Sitemap
    | Notified Notification
    | ToInvite Invite.Msg
    | ToProfile Profile.Msg
    | ToIntegrations Integrations.Msg
    | ToSettings Settings.Msg
    | ToCurrentProfile CP.Msg
    | ToNotifications Notifications.Msg
    | ToggleSidebar
    | TouchSidebarStart Float
    | TouchSidebarMove Float
    | TouchSidebarEnd
    | UpdateSidebar Time


type alias Model =
    { now : Timestamp
    , suspended : Bool
    , company : Company
    , user : User
    , team : Team
    , teamMembers : List User
    , timezones : List Timezone
    , integrationStates : IntegrationStates
    , route : Sitemap
    , invite : Invite.Model
    , profile : Profile.Model
    , integrations : Integrations.Model
    , settings : Settings.Model ContextMsg
    , currentProfile : CP.Model
    , notifications : Notifications.Model
    , sidebarHidden : Bool
    , sidebarTouching : Bool
    , sidebarOffsetStartX : Float
    , sidebarOffsetCurrentX : Float
    , sidebarOffsetX : Float
    }


type alias Flags =
    { now : Timestamp
    , suspended : Bool
    , company : Company
    , user : ContextUser
    , team : List ContextUser
    , timezones : List Timezone
    , integrationStates : IntegrationStates
    , viewportWidth : Int
    }
