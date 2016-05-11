module Components.CurrentProfile exposing (..)

import Api exposing (Errors, getJson, deletePlain)
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
import Types exposing (User)
import Util exposing (boolFromMaybe, pure)


type ParentMessage
    = RemoveAvatar


type Message
    = Submit
    | DeleteAvatar
    | ToParent ParentMessage
    | ToForm Form.Msg
    | UploadUriError (HttpBuilder.Error Errors)
    | UploadUriSuccess (HttpBuilder.Response String)


type alias Profile =
    { name : String }


type alias Model =
    { form : Form () Profile
    , pending : Bool
    , uploadUri : Maybe String
    }


validate : Validation () Profile
validate =
    form1 Profile
        (get "name" string)


init : User -> ( Model, Cmd Message )
init user =
    ( { form = Form.initial [ ( "name", Text user.name ) ] validate
      , pending = False
      , uploadUri = Nothing
      }
    , createUploadUri
    )


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        Submit ->
            -- FIXME: implement submit
            pure model

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


view : Model -> Html Message
view { form, pending, uploadUri } =
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

        workday label name =
            let
                options subname =
                    FC.defaultOptions (name ++ "-" ++ subname)

                hours subname =
                    FC.selectInput (options subname) [] form
                        |> Html.map ToForm
            in
                div [ class "input-group" ]
                    [ Html.label [] [ text label ]
                    , hours "start"
                    , Html.label [] [ text "to" ]
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
                , selectInput "Timezone" "timezone" []
                , h4 [] [ text "Workdays" ]
                , workday "Monday" "monday"
                , workday "Tuesday" "tuesday"
                , FC.submitWithOptions { label = "Update", disabled = pending }
                ]
            ]


createUploadUri : Cmd Message
createUploadUri =
    getJson UploadUriError UploadUriSuccess ("uri" := Json.string) "upload"


deleteAvatar : Cmd Message
deleteAvatar =
    let
        m =
            always <| ToParent RemoveAvatar
    in
        deletePlain m m "avatar"
