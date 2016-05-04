module Types where

import Dict exposing (Dict)

import Timestamp exposing (Timestamp, Timezone, TimezoneOffset)
import Routes exposing (Sitemap)

import Components.Invite as Invite


type Role
  = Main
  | Manager
  | Member

type alias Company
  = { name : String
    }

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

type alias Team
  = Dict (Timezone, TimezoneOffset) (List User)

type alias Model
  = { now : Timestamp
    , company : Company
    , user : User
    , team : Team
    , route : Sitemap
    , invite : Invite.Model
    }

type Message
  = NoOp
  | Tick Timestamp
  | TimezoneChanged Timezone
  | PathChanged String
  | RouteTo Sitemap
  | ToInvite Invite.Message
