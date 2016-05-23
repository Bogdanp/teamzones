module Types exposing (..)

import Dict exposing (Dict)
import Html exposing (Html, Attribute)
import Routes exposing (Sitemap)
import Timestamp exposing (Timezone, TimezoneOffset)


type alias Notification =
    { hidden : Bool
    , level : String
    , message : String
    }


type alias Company =
    { name : String
    }


type UserRole
    = Main
    | Manager
    | Member


type alias Workday =
    { start : Int
    , end : Int
    }


type alias Workdays =
    { monday : Workday
    , tuesday : Workday
    , wednesday : Workday
    , thursday : Workday
    , friday : Workday
    , saturday : Workday
    , sunday : Workday
    }


type alias ContextUser =
    { role : String
    , firstName : String
    , lastName : String
    , email : String
    , avatar : String
    , smallAvatar : String
    , timezone : Timezone
    , workdays : Workdays
    }


type alias IntegrationStates =
    { gCalendar : Bool }


type alias User =
    { role : UserRole
    , firstName : String
    , lastName : String
    , fullName : String
    , email : String
    , avatar : Maybe String
    , smallAvatar : Maybe String
    , timezone : Timezone
    , workdays : Workdays
    }


type alias Team =
    Dict ( Timezone, TimezoneOffset ) (List User)


type alias AnchorTo msg =
    Sitemap -> List (Attribute msg) -> List (Html msg) -> Html msg
