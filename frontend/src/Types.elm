module Types where

import Dict exposing (Dict)

import Timestamp exposing (Timestamp, Timezone)


type alias Company
  = { name : String
    }

type alias User
  = { email : String
    , name : String
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
