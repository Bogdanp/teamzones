module Types where

import Dict exposing (Dict)
import Html exposing (Html, Attribute)

import Routes exposing (Sitemap)
import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)


type alias Company
  = { name : String
    }


type UserRole
  = Main
  | Manager
  | Member

type alias Workday
  = { start : Int
    , end : Int
    }

type alias Workdays
  = { monday : Workday
    , tuesday : Workday
    , wednesday : Workday
    , thursday : Workday
    , friday : Workday
    , saturday : Workday
    , sunday : Workday
    }

type alias ContextUser
  = { role : String
    , name : String
    , email : String
    , avatar : String
    , timezone : Timezone
    , workdays : Workdays
    }

type alias User
  = { role : UserRole
    , name : String
    , email : String
    , avatar : Maybe String
    , timezone : Timezone
    , workdays : Workdays
    }


type alias Team
  = Dict (Timezone, TimezoneOffset) (List User)


type alias AnchorTo
  = Sitemap -> List Attribute -> List Html -> Html
