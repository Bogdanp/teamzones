module Types where

import Dict exposing (Dict)

import Timestamp exposing (Timestamp, Timezone)


type alias Member
  = {}

type alias User
  = { email : String
    }

type alias Model
  = { now : Timestamp
    , user : User
    , team : Dict Timezone (List Member)
    }


type Message
  = Tick Timestamp
