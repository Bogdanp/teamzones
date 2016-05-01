module Main where

import Effects exposing (Never)
import Html exposing (Html, text)
import StartApp exposing (App, start)
import Task exposing (Task)

import Timestamp exposing (Timestamp)
import Types exposing (..)
import Update exposing (init, update)
import View exposing (view)

app : App Model
app =
  start { init = init now company user
        , view = view
        , update = update
        , inputs = [ Signal.map Tick timestamps ]
        }

main : Signal Html
main = app.html

port tasks : Signal (Task Never ())
port tasks =
  app.tasks

port now : Timestamp
port timestamps : Signal Timestamp

port company : Company
port user : User
port team : List User
