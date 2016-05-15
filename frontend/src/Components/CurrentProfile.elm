module Components.CurrentProfile exposing (..)

import Api exposing (Errors, getJson, deletePlain, postPlain)
import Components.Form as FC
import Components.Page exposing (page)
import Form exposing (Form)
import Form.Field exposing (Field(..))
import Form.Validate as Validate exposing (..)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import HttpBuilder
import Json.Decode as Json exposing ((:=))
import Json.Encode
import Task
import Timestamp exposing (Timezone, showTimezone)
import Types exposing (Workday, Workdays, User)
import Util exposing ((=>), boolFromMaybe, pure)


type ParentMsg
    = RemoveAvatar
    | UpdateCurrentUser Profile


type Msg
    = Submit
    | DeleteAvatar
    | ToParent ParentMsg
    | ToForm Form.Msg
    | UploadUriError (HttpBuilder.Error Errors)
    | UploadUriSuccess (HttpBuilder.Response String)
    | ProfileError (HttpBuilder.Error Errors)
    | ProfileSuccess (HttpBuilder.Response String)


type alias Profile =
    { name : String
    , timezone : String
    , workdays : Workdays
    }


type alias Model =
    { profile : Profile
    , form : Form () Profile
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
        (get "name" string)
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
          , pending = False
          , uploadUri = Nothing
          , timezones = timezones
          }
        , createUploadUri
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
                        pure { model | form = form }

                    Just profile ->
                        ( { model | form = form, profile = profile, pending = True }
                        , updateProfile profile
                        )

        DeleteAvatar ->
            ( model, deleteAvatar )

        ToParent _ ->
            pure model

        ToForm m ->
            pure { model | form = Form.update m model.form }

        UploadUriError _ ->
            ( model, createUploadUri )

        UploadUriSuccess response ->
            pure { model | uploadUri = Just response.data }

        ProfileError _ ->
            pure { model | pending = False }

        ProfileSuccess response ->
            ( { model | pending = False }
            , UpdateCurrentUser model.profile
                |> Task.succeed
                |> Task.perform ToParent ToParent
            )


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
view { form, pending, uploadUri, timezones } =
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
                        , input
                            [ class "sm-ml"
                            , type' "button"
                            , value "Delete profile picture"
                            , onClick DeleteAvatar
                            ]
                            []
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


createUploadUri : Cmd Msg
createUploadUri =
    getJson UploadUriError UploadUriSuccess ("uri" := Json.string) "upload"


deleteAvatar : Cmd Msg
deleteAvatar =
    let
        m =
            always <| ToParent RemoveAvatar
    in
        deletePlain m m "avatar"


encodeWorkday : Workday -> Json.Encode.Value
encodeWorkday workday =
    Json.Encode.object
        [ "start" => Json.Encode.int workday.start
        , "end" => Json.Encode.int workday.end
        ]


encodeWorkdays : Workdays -> Json.Encode.Value
encodeWorkdays workdays =
    Json.Encode.object
        [ "monday" => encodeWorkday workdays.monday
        , "tuesday" => encodeWorkday workdays.tuesday
        , "wednesday" => encodeWorkday workdays.wednesday
        , "thursday" => encodeWorkday workdays.thursday
        , "friday" => encodeWorkday workdays.friday
        , "saturday" => encodeWorkday workdays.saturday
        , "sunday" => encodeWorkday workdays.sunday
        ]


encodeProfile : Profile -> Json.Encode.Value
encodeProfile profile =
    Json.Encode.object
        [ "name" => Json.Encode.string profile.name
        , "timezone" => Json.Encode.string profile.timezone
        , "workdays" => encodeWorkdays profile.workdays
        ]


updateProfile : Profile -> Cmd Msg
updateProfile profile =
    postPlain ProfileError ProfileSuccess (encodeProfile profile) "profile"
