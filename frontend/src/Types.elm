module Types where

import Dict exposing (Dict)

import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)


type alias Company
  = { name : String
    }


type UserRole
  = Main
  | Manager
  | Member

type alias ContextUser
  = { role : String
    , name : String
    , email : String
    , avatar : String
    , timezone : Timezone
    }

type alias User
  = { role : UserRole
    , name : String
    , email : String
    , avatar : Maybe String
    , timezone : Timezone
    }


type alias Team
  = Dict (Timezone, TimezoneOffset) (List User)
