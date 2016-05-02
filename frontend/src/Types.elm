module Types where

import Dict exposing (Dict)

import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)
import Routes exposing (Sitemap)


type alias Company
  = { name : String
    }

type Role
  = Main
  | Manager
  | Member

type alias ContextUser
  = { role : Int
    , name : String
    , email : String
    , avatar : String
    , timezone : Timezone
    }

type alias User
  = { role : Role
    , name : String
    , email : String
    , avatar : Maybe String
    , timezone : Timezone
    }

type alias Model
  = { now : Timestamp
    , company : Company
    , user : User
    , team : Dict (Timezone, TimezoneOffset) (List User)
    , route : Sitemap
    }


type Message
  = NoOp
  | Tick Timestamp
  | TimezoneChanged Timezone
  | PathChanged String
  | RouteTo Sitemap
