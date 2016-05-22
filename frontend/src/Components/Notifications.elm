module Components.Notifications
    exposing
        ( Model
        , Msg
        , init
        , update
        , append
        , error
        , warning
        , info
        , view
        )

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Ports exposing (notify)
import Process
import Task
import Time
import Types exposing (Notification)
import Util exposing ((=>))


type Msg
    = Notify Notification
    | Dismiss Id
    | GC (List Id)


type alias Id =
    Int


type alias Model =
    { seq : Id
    , notifications : Dict Id Notification
    }


init : Model
init =
    { seq = 0
    , notifications = Dict.empty
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ seq, notifications } as model) =
    case msg of
        Notify x ->
            append x model

        Dismiss id ->
            let
                xs =
                    Dict.update id (Maybe.map (\n -> { n | hidden = True })) notifications

                empty =
                    Dict.toList xs
                        |> List.all (snd >> .hidden)

                fx =
                    if empty then
                        let
                            gc =
                                always (GC (Dict.toList xs |> List.map fst))
                        in
                            Task.perform gc gc (Process.sleep (1 * Time.second))
                    else
                        Cmd.none
            in
                { model | notifications = xs } ! [ fx ]

        GC ids ->
            let
                xs =
                    List.foldl Dict.remove notifications ids
            in
                { model | notifications = xs } ! []


append : Notification -> Model -> ( Model, Cmd Msg )
append x ({ seq, notifications } as model) =
    let
        dismiss =
            always (Dismiss seq)

        xs =
            Dict.insert seq x notifications
    in
        { model | seq = seq + 1, notifications = xs }
            ! [ Task.perform dismiss dismiss (Process.sleep (5 * Time.second))
              ]


error : String -> Cmd msg
error message =
    notify
        { hidden = False
        , level = "error"
        , message = message
        }


warning : String -> Cmd msg
warning message =
    notify
        { hidden = False
        , level = "warning"
        , message = message
        }


info : String -> Cmd msg
info message =
    notify
        { hidden = False
        , level = "info"
        , message = message
        }


view : Model -> Html Msg
view { notifications } =
    let
        xs =
            Dict.toList notifications
                |> List.sortBy fst
                |> List.map notification
    in
        div [ id "notifications" ] xs


notification : ( Id, Notification ) -> Html Msg
notification ( id, n ) =
    div
        [ classList
            [ "hidden" => n.hidden
            , "notification" => True
            , n.level => True
            ]
        ]
        [ span [ onClick (Dismiss id) ] [ text n.message ] ]
