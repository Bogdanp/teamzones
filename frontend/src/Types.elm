module Types where

import Dict exposing (Dict)

import Timestamp exposing (Timestamp, Timezone)


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
    , team : Dict Timezone (List User)
    }


type Message
  = Tick Timestamp
  | TimezoneChanged Timezone
