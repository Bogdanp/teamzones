module Components.Meetings exposing (Msg, Model, init, update, view)

import Components.Common exposing (heading)
import Components.Form as FC
import Components.Notifications exposing (info)
import Components.Page exposing (page)
import Date
import DatePicker exposing (DatePicker, defaultSettings)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..), IntegrationsSitemap(..))
import Timestamp exposing (Timestamp)
import Types exposing (AnchorTo, IntegrationStates)
import Util exposing (dateTuple)


type Msg
    = RouteTo Sitemap
    | ToDatePicker DatePicker.Msg
    | Submit


type alias Context =
    { now : Timestamp
    , integrationStates : IntegrationStates
    }


type alias Model =
    { datePicker : DatePicker
    }


init : Context -> ( Model, Cmd Msg )
init { now, integrationStates } =
    let
        isDisabled date =
            dateTuple date < dateTuple (Date.fromTime now)

        ( datePicker, datePickerFx ) =
            DatePicker.init { defaultSettings | isDisabled = isDisabled }

        model =
            { datePicker = datePicker
            }
    in
        if integrationStates.gCalendar then
            model ! [ Cmd.map ToDatePicker datePickerFx ]
        else
            model
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

        Submit ->
            model ! []


view : Model -> Html Msg
view model =
    page "Meetings"
        [ FC.form Submit
            [ heading "Schedule a meeting"
            , div [ class "input-group" ]
                [ label [] [ text "Date" ]
                , div [ class "input" ]
                    [ DatePicker.view model.datePicker
                        |> Html.map ToDatePicker
                    ]
                ]
            ]
        ]


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
