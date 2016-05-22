module Components.CurrentProfile exposing (..)

import Api exposing (Error, Response)
import Api.Profile as ProfileApi exposing (Profile, createUploadUri, deleteAvatar, updateProfile)
import Components.ConfirmationButton as CB
import Components.Form as FC
import Components.Notifications exposing (info)
import Components.Page exposing (page)
import Form exposing (Form)
import Form.Field exposing (Field(..))
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Task
import Timestamp exposing (Timezone, showTimezone)
import Types exposing (Workday, Workdays, User)
import Util exposing ((=>), boolFromMaybe)


type ParentMsg
    = RemoveAvatar
    | UpdateCurrentUser Profile


type Msg
    = Submit
    | ToParent ParentMsg
    | ToForm Form.Msg
    | ToDeleteAvatarButton CB.Msg
    | UploadUriError Error
    | UploadUriSuccess (Response String)
    | ProfileError Error
    | ProfileSuccess (Response String)


type alias Model =
    { profile : Profile
    , form : Form () Profile
    , deleteAvatarButton : CB.Model
    , pending : Bool
    , uploadUri : Maybe String
    , timezones : List Timezone
    }


validateWorkday : String -> Validation () Workday
validateWorkday prefix =
    form2 Workday
        (get (prefix ++ "-start") int)
        (get (prefix ++ "-end") int)


validateWorkdays : Validation () Workdays
validateWorkdays =
    form7 Workdays
        (validateWorkday "monday")
        (validateWorkday "tuesday")
        (validateWorkday "wednesday")
        (validateWorkday "thursday")
        (validateWorkday "friday")
        (validateWorkday "saturday")
        (validateWorkday "sunday")


validate : Validation () Profile
validate =
    form3 Profile
        (get "name" (string `andThen` minLength 3 `andThen` maxLength 50))
        (get "timezone" string)
        validateWorkdays


init : User -> List Timezone -> ( Model, Cmd Msg )
init user timezones =
    let
        select =
            Select << toString

        profile =
            Profile user.name user.timezone user.workdays

        values =
            [ ( "name", Text user.name )
            , ( "timezone", Select user.timezone )
            , ( "monday-start", select user.workdays.monday.start )
            , ( "monday-end", select user.workdays.monday.end )
            , ( "tuesday-start", select user.workdays.tuesday.start )
            , ( "tuesday-end", select user.workdays.tuesday.end )
            , ( "wednesday-start", select user.workdays.wednesday.start )
            , ( "wednesday-end", select user.workdays.wednesday.end )
            , ( "thursday-start", select user.workdays.thursday.start )
            , ( "thursday-end", select user.workdays.thursday.end )
            , ( "friday-start", select user.workdays.friday.start )
            , ( "friday-end", select user.workdays.friday.end )
            , ( "saturday-start", select user.workdays.saturday.start )
            , ( "saturday-end", select user.workdays.saturday.end )
            , ( "sunday-start", select user.workdays.sunday.start )
            , ( "sunday-end", select user.workdays.sunday.end )
            ]
    in
        ( { profile = profile
          , form = Form.initial values validate
          , deleteAvatarButton = CB.init "Delete profile picture"
          , pending = False
          , uploadUri = Nothing
          , timezones = timezones
          }
        , Task.perform UploadUriError UploadUriSuccess createUploadUri
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Submit ->
            let
                form =
                    Form.update Form.Submit model.form

                profile =
                    Form.getOutput form
            in
                case profile of
                    Nothing ->
                        { model | form = form } ! []

                    Just profile ->
                        { model
                            | form = form
                            , profile = profile
                            , pending = True
                        }
                            ! [ updateProfile profile |> Task.perform ProfileError ProfileSuccess ]

        ToParent _ ->
            model ! []

        ToForm m ->
            { model | form = Form.update m model.form } ! []

        ToDeleteAvatarButton ((CB.ToParent (CB.Confirm)) as msg) ->
            let
                message _ =
                    ToParent RemoveAvatar
            in
                { model | deleteAvatarButton = CB.update msg model.deleteAvatarButton }
                    ! [ Task.perform message message deleteAvatar ]

        ToDeleteAvatarButton msg ->
            { model | deleteAvatarButton = CB.update msg model.deleteAvatarButton } ! []

        UploadUriError _ ->
            model ! [ Task.perform UploadUriError UploadUriSuccess createUploadUri ]

        UploadUriSuccess response ->
            { model | uploadUri = Just response.data } ! []

        ProfileError _ ->
            { model | pending = False } ! []

        ProfileSuccess response ->
            { model | pending = False }
                ! [ info "Your profile has been updated."
                  , UpdateCurrentUser model.profile
                        |> Task.succeed
                        |> Task.perform ToParent ToParent
                  ]


hoursInDay : List ( String, String )
hoursInDay =
    [ ( "0", "Off" )
    , ( "1", "1:00 AM" )
    , ( "2", "2:00 AM" )
    , ( "3", "3:00 AM" )
    , ( "4", "4:00 AM" )
    , ( "5", "5:00 AM" )
    , ( "6", "6:00 AM" )
    , ( "7", "7:00 AM" )
    , ( "8", "8:00 AM" )
    , ( "9", "9:00 AM" )
    , ( "10", "10:00 AM" )
    , ( "11", "11:00 AM" )
    , ( "12", "12:00 PM" )
    , ( "13", "1:00 PM" )
    , ( "14", "2:00 PM" )
    , ( "15", "3:00 PM" )
    , ( "16", "4:00 PM" )
    , ( "17", "5:00 PM" )
    , ( "18", "6:00 PM" )
    , ( "19", "7:00 PM" )
    , ( "20", "8:00 PM" )
    , ( "21", "9:00 PM" )
    , ( "22", "10:00 PM" )
    , ( "23", "11:00 PM" )
    , ( "24", "12:00 AM" )
    ]


view : Model -> Html Msg
view { form, deleteAvatarButton, pending, uploadUri, timezones } =
    let
        textInput label name =
            let
                options =
                    FC.defaultOptions name
            in
                FC.textInput { options | label = Just label } form
                    |> Html.map ToForm

        selectInput label name xs =
            let
                options =
                    FC.defaultOptions name
            in
                FC.selectInput { options | label = Just label } xs form
                    |> Html.map ToForm

        uploadPending =
            not <| boolFromMaybe uploadUri

        timezoneValues =
            List.map2 (flip (,) << showTimezone) timezones timezones

        workday label name =
            let
                hours subname =
                    let
                        subname' =
                            name ++ "-" ++ subname

                        opts =
                            FC.defaultOptions subname'
                    in
                        FC.selectInput opts hoursInDay form
                            |> Html.map ToForm
            in
                div [ class "input-group workday" ]
                    [ Html.label [] [ text label ]
                    , hours "start"
                    , Html.label [ class "workday-label" ] [ text "until" ]
                    , hours "end"
                    ]
    in
        page "Your Profile"
            [ Html.form
                [ action (Maybe.withDefault "" uploadUri)
                , class "form-group no-pt"
                , method "POST"
                , enctype "multipart/form-data"
                ]
                [ div [ class "input-group" ]
                    [ label [ for "avatar-file" ]
                        [ text "Profile picture" ]
                    , div [ class "input" ]
                        [ input
                            [ type' "file"
                            , id "avatar-file"
                            , name "avatar-file"
                            , accept "image/*"
                            ]
                            []
                        ]
                    ]
                , div [ class "input-group" ]
                    [ div [ class "spacer" ] []
                    , div [ class "input" ]
                        [ input
                            [ type' "submit"
                            , value "Upload"
                            , disabled uploadPending
                            ]
                            []
                        , CB.view deleteAvatarButton |> Html.map ToDeleteAvatarButton
                        ]
                    ]
                ]
            , FC.form Submit
                [ h4 [] [ text "Personal information" ]
                , textInput "Name" "name"
                , selectInput "Timezone" "timezone" timezoneValues
                , h4 [] [ text "Workdays" ]
                , workday "Monday" "monday"
                , workday "Tuesday" "tuesday"
                , workday "Wednesday" "wednesday"
                , workday "Thursday" "thursday"
                , workday "Friday" "friday"
                , workday "Saturday" "saturday"
                , workday "Sunday" "sunday"
                , FC.submitWithOptions { label = "Update", disabled = pending }
                ]
            ]
