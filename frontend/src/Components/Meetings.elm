module Components.Meetings exposing (Msg, Model, init, update, view)

import DatePicker exposing (DatePicker)
import Components.Notifications exposing (info)
import Components.Page exposing (page)
import Html exposing (..)
import Html.App as Html
import Routes exposing (Sitemap(..), IntegrationsSitemap(..))
import Types exposing (AnchorTo, IntegrationStates)
import Util


type Msg
    = RouteTo Sitemap
    | ToDatePicker DatePicker.Msg


type alias Context =
    { integrationStates : IntegrationStates }


type alias Model =
    { datePicker : DatePicker }


init : Context -> ( Model, Cmd Msg )
init { integrationStates } =
    let
        ( datePicker, fx ) =
            DatePicker.init DatePicker.defaultSettings
    in
        if integrationStates.gCalendar then
            { datePicker = datePicker } ! [ Cmd.map ToDatePicker fx ]
        else
            { datePicker = datePicker }
                ! [ Routes.navigateTo (IntegrationsR (GCalendarR ()))
                  , info "You must connect your Google Calendar account before you can set up meetings."
                  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        ToDatePicker msg ->
            let
                ( datePicker, fx, mdate ) =
                    DatePicker.update msg model.datePicker
            in
                { model | datePicker = datePicker } ! [ Cmd.map ToDatePicker fx ]


view : Model -> Html Msg
view model =
    page "Meetings"
        [ DatePicker.view model.datePicker
            |> Html.map ToDatePicker
        ]


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
