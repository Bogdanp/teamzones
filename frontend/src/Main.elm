module Main exposing (main)

import Model exposing (Model, Msg(..), Flags)
import Navigation
import Ports exposing (timestamps, timezones, notifications)
import Update exposing (init, update, urlUpdate)
import Routes exposing (parsePath)
import View exposing (view)


main : Program Flags
main =
    Navigation.programWithFlags (Navigation.makeParser parsePath)
        { init = init
        , view = view
        , update = update
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ timestamps Tick
        , timezones TimezoneChanged
        , notifications Notified
        ]
