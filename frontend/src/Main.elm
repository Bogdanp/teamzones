port module Main exposing (..)

import Html.App as Html
import Model exposing (Model, Msg(..), Flags)
import Ports exposing (path, timestamps, timezones)
import Update exposing (init, update)
import View exposing (view)


main : Program Flags
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ path PathChanged
        , timestamps Tick
        , timezones TimezoneChanged
        ]
