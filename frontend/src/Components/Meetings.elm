module Components.Meetings exposing (Msg, Model, init, update, view)

import Components.Common exposing (heading)
import Components.Form as FC
import Components.Notifications exposing (info)
import Components.Page exposing (page)
import Components.TimePicker as TimePicker
import Components.TimePicker.Time as Time exposing (Time)
import Date exposing (Date)
import DatePicker exposing (DatePicker, defaultSettings)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Lazy exposing (lazy)
import Routes exposing (Sitemap(..), IntegrationsSitemap(..))
import Timestamp exposing (Timestamp)
import Types exposing (AnchorTo, IntegrationStates, User)
import Util exposing ((?>), (??), (=>), dateTuple)


type Msg
    = RouteTo Sitemap
    | ToStartDatePicker DatePicker.Msg
    | ToStartTimePicker TimePicker.Msg
    | ToEndDatePicker DatePicker.Msg
    | ToEndTimePicker TimePicker.Msg
    | Submit


type alias Context =
    { now : Timestamp
    , teamMembers : List User
    , integrationStates : IntegrationStates
    }


type alias Model =
    { startDate : Date
    , startTime : Time
    , startDatePicker : DatePicker
    , startTimePicker : TimePicker.Model
    , endDate : Date
    , endTime : Time
    , endDatePicker : DatePicker
    , endTimePicker : TimePicker.Model
    , teamMembers : List User
    }


init : Context -> ( Model, Cmd Msg )
init { now, teamMembers, integrationStates } =
    let
        isDisabled date =
            dateTuple date < dateTuple (Date.fromTime now)

        later =
            now - (toFloat <| floor now `rem` 600000) + 900000

        startDate =
            Date.fromTime later

        startTime =
            Timestamp.format "h:mmA" later

        endDate =
            startDate

        endTime =
            startTime

        ( startDatePicker, startDatePickerFx ) =
            DatePicker.init { defaultSettings | isDisabled = isDisabled, pickedDate = Just startDate }

        startTimePicker =
            TimePicker.initWithValue startTime

        ( endDatePicker, endDatePickerFx ) =
            DatePicker.init { defaultSettings | isDisabled = isDisabled, pickedDate = Just endDate }

        endTimePicker =
            TimePicker.initWithValue endTime

        model =
            { startDate = startDate
            , startTime = Time.parse startTime ?> Time.zero
            , startDatePicker = startDatePicker
            , startTimePicker = startTimePicker
            , endDate = endDate
            , endTime = Time.parse endTime ?> Time.zero
            , endDatePicker = endDatePicker
            , endTimePicker = endTimePicker
            , teamMembers = teamMembers
            }
    in
        if integrationStates.gCalendar then
            model
                ! [ Cmd.map ToStartDatePicker startDatePickerFx
                  , Cmd.map ToEndDatePicker endDatePickerFx
                  ]
        else
            model
                ! [ Routes.navigateTo (IntegrationsR (GCalendarR ()))
                  , info "You must connect your Google Calendar account before you can set up meetings."
                  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ startDate, startTime, endDate, endTime } as model) =
    case msg of
        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        ToStartDatePicker msg ->
            let
                ( startDatePicker, startDatePickerFx, mdate ) =
                    DatePicker.update msg model.startDatePicker

                ( startDate, endDate, endDatePicker, endDatePickerFx ) =
                    case mdate of
                        Nothing ->
                            ( model.startDate, model.endDate, model.endDatePicker, Cmd.none )

                        Just date ->
                            let
                                ( ed, dp, dpFx ) =
                                    initEndDatePicker date model.endDate
                            in
                                ( date, ed, dp, dpFx )
            in
                prepareTimes
                    { model
                        | startDate = startDate
                        , startDatePicker = startDatePicker
                        , endDate = endDate
                        , endDatePicker = endDatePicker
                    }
                    ! [ Cmd.map ToStartDatePicker startDatePickerFx
                      , Cmd.map ToEndDatePicker endDatePickerFx
                      ]

        ToEndDatePicker msg ->
            let
                ( endDatePicker, endDatePickerFx, mdate ) =
                    DatePicker.update msg model.endDatePicker
            in
                prepareTimes
                    { model
                        | endDate = mdate ?> endDate
                        , endDatePicker = endDatePicker
                    }
                    ! [ Cmd.map ToEndDatePicker endDatePickerFx
                      ]

        ToStartTimePicker msg ->
            let
                ( startTimePicker, mtime ) =
                    TimePicker.update msg model.startTimePicker
            in
                prepareTimes
                    { model
                        | startTime = mtime ?> startTime
                        , startTimePicker = startTimePicker
                    }
                    ! []

        ToEndTimePicker msg ->
            let
                ( endTimePicker, mtime ) =
                    TimePicker.update msg model.endTimePicker
            in
                { model
                    | endTime = mtime ?> endTime
                    , endTimePicker = endTimePicker
                }
                    ! []

        Submit ->
            model ! []


view : Model -> Html Msg
view ({ startDatePicker, startTimePicker, endDatePicker, endTimePicker, teamMembers } as model) =
    page "Meetings"
        [ FC.formWithAttrs Submit
            [ class "scheduler" ]
            [ div [ class "column" ]
                [ heading "Schedule a meeting"
                , div [ class "range" ]
                    [ Html.map ToStartDatePicker <| lazy DatePicker.view startDatePicker
                    , Html.map ToStartTimePicker <| lazy TimePicker.view startTimePicker
                    , span [] [ text "to" ]
                    , Html.map ToEndDatePicker <| lazy DatePicker.view endDatePicker
                    , Html.map ToEndTimePicker <| lazy TimePicker.view endTimePicker
                    ]
                , textarea [ class "description", placeholder "Description" ] []
                , br [] []
                , input
                    [ type' "submit"
                    , value "Schedule meeting"
                    ]
                    []
                ]
            , div [ class "column" ]
                [ heading "Attendees"
                , table []
                    [ thead []
                        [ tr []
                            [ td [ style [ "width" => "30px" ] ] [ checkbox "all" ]
                            , td [] [ text "Name" ]
                            , td [ style [ "width" => "60%" ] ] [ text "Status" ]
                            ]
                        ]
                    , tbody [] (List.map memberRow teamMembers)
                    ]
                ]
            ]
        ]


checkbox : String -> Html Msg
checkbox elId =
    input [ type' "checkbox", id elId ] []


memberRow : User -> Html Msg
memberRow { fullName, email } =
    let
        id =
            "checkbox--" ++ email
    in
        tr []
            [ td [] [ checkbox id ]
            , td [] [ label [ for id ] [ text fullName ] ]
            , td [] []
            ]


prepareTimes : Model -> Model
prepareTimes ({ startDate, startTime, endDate, endTime } as model) =
    let
        st =
            if datesEq startDate endDate && Time.compare startTime endTime == GT then
                startTime
            else
                Time.zero

        ( et, tp ) =
            initEndTimePicker st endTime
    in
        { model
            | endTime = et
            , endTimePicker = tp
        }


initEndDatePicker : Date -> Date -> ( Date, DatePicker, Cmd DatePicker.Msg )
initEndDatePicker startDate endDate =
    let
        isDisabled d =
            dateTuple d < dateTuple startDate

        endDate' =
            if isDisabled endDate then
                startDate
            else
                endDate

        ( dp, dpFx ) =
            DatePicker.init
                { defaultSettings
                    | isDisabled = isDisabled
                    , pickedDate = Just endDate'
                }
    in
        ( endDate', dp, dpFx )


initEndTimePicker : Time -> Time -> ( Time, TimePicker.Model )
initEndTimePicker startTime endTime =
    let
        et =
            if Time.compare startTime endTime == GT then
                startTime
            else
                endTime
    in
        ( et, TimePicker.initWithMin startTime et )


datesEq : Date -> Date -> Bool
datesEq a b =
    dateTuple a == dateTuple b


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
